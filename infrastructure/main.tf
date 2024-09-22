terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cariad-frame-tf-state"
    storage_account_name = "sacariadframetfstate"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
}

module "common_naming" {
  source             = "./modules/common_naming"
  location_short_eu  = var.location_short_eu
  location_short_us  = var.location_short_us
  project_short_name = var.project_short_name
  environment        = var.environment
}

data "azurerm_resource_group" "rg_eu" {
  name     = "rg-${var.project_name}-${var.environment}-euw"
}

data "azurerm_resource_group" "rg_us" {
  name     = "rg-${var.project_name}-${var.environment}-usw"
}

module "virtual_network_eu" {
  source                  = "./modules/virtual_network"
  resource_group_name     = data.azurerm_resource_group.rg_eu.name
  location                = data.azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu
  address_space           = ["10.1.0.0/16"]
  subnet_name             = "subnet"
  subnet_address_prefixes = ["10.1.1.0/24"]
}

module "virtual_network_us" {
  source                  = "./modules/virtual_network"
  resource_group_name     = data.azurerm_resource_group.rg_us.name
  location                = data.azurerm_resource_group.rg_us.location
  resource_name_specifier = module.common_naming.resource_name_specifier_us
  address_space           = ["10.2.0.0/16"]
  subnet_name             = "subnet"
  subnet_address_prefixes = ["10.2.1.0/24"]
}

resource "azurerm_virtual_network_peering" "eu-to-us" {
  name                      = "peer-${var.project_name}-${var.environment}-euw"
  resource_group_name       = data.azurerm_resource_group.rg_eu.name
  virtual_network_name      = module.virtual_network_eu.vnet_name
  remote_virtual_network_id = module.virtual_network_us.id
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "us-to-eu" {
  name                      = "peer-${var.project_name}-${var.environment}-usw"
  resource_group_name       = data.azurerm_resource_group.rg_us.name
  virtual_network_name      = module.virtual_network_us.vnet_name
  remote_virtual_network_id = module.virtual_network_eu.id
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
}

module "key_vault" {
  source                  = "./modules/key_vault"
  resource_group_name     = data.azurerm_resource_group.rg_eu.name
  location                = data.azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu
  principal_ids            = var.principal_ids
}

module "vm_client1" {
  source                  = "./modules/vm_client"
  resource_group_name_eu  = data.azurerm_resource_group.rg_eu.name
  resource_group_name_us  = data.azurerm_resource_group.rg_us.name
  location                = data.azurerm_resource_group.rg_us.location
  resource_name_specifier = module.common_naming.resource_name_specifier_us
  client_number           = 1
  subnet_id               = module.virtual_network_us.subnet_id

  key_vault_id = module.key_vault.id

  storage_account_name              = module.storage_account.name
  storage_account_key               = module.storage_account.key
  storage_account_connection_string = module.storage_account.connection_string
  fileshare_name                    = module.storage_account.fileshare_name
  scripts_container_name            = module.scripts_storage.scripts_container_name
  scripts_storage_account_name      = module.scripts_storage.name

  dns_zone_name                     = module.private_link.dns_zone_name

  bootstrapping_script_name = "bootstrapping.ps1"
  create_service_script_name = "create_service.ps1"
  bootstrapping_md5 = time_sleep.wait_after_blob_upload.triggers["bootstrapping_md5"]
  create_service_md5 = time_sleep.wait_after_blob_upload.triggers["create_service_md5"]

  depends_on = [
    azurerm_virtual_network_peering.eu-to-us,
    azurerm_virtual_network_peering.us-to-eu,
    module.virtual_network_eu,
    module.virtual_network_us,
    module.key_vault,
    azurerm_storage_blob.bootstrapping_script,
    azurerm_storage_blob.create_service_script
  ]
}

module "vm_client2" {
  source                  = "./modules/vm_client"
  resource_group_name_eu  = data.azurerm_resource_group.rg_eu.name
  resource_group_name_us  = data.azurerm_resource_group.rg_us.name
  location                = data.azurerm_resource_group.rg_us.location
  resource_name_specifier = module.common_naming.resource_name_specifier_us
  client_number           = 2
  subnet_id               = module.virtual_network_us.subnet_id

  key_vault_id = module.key_vault.id

  storage_account_name              = module.storage_account.name
  scripts_storage_account_name      = module.scripts_storage.name
  storage_account_key               = module.storage_account.key
  storage_account_connection_string = module.storage_account.connection_string
  fileshare_name                    = module.storage_account.fileshare_name
  scripts_container_name            = module.scripts_storage.scripts_container_name
  dns_zone_name                     = module.private_link.dns_zone_name

  bootstrapping_script_name = "bootstrapping.ps1"
  create_service_script_name = "create_service.ps1"
  bootstrapping_md5 = time_sleep.wait_after_blob_upload.triggers["bootstrapping_md5"]
  create_service_md5 = time_sleep.wait_after_blob_upload.triggers["create_service_md5"]

  depends_on = [
    azurerm_virtual_network_peering.eu-to-us,
    azurerm_virtual_network_peering.us-to-eu,
    module.virtual_network_eu,
    module.virtual_network_us,
    module.key_vault,
    azurerm_storage_blob.bootstrapping_script,
    azurerm_storage_blob.create_service_script
  ]
}

module "scripts_storage"{
  source                  = "./modules/scripts_storage"
  resource_group_name     = data.azurerm_resource_group.rg_eu.name
  location                = data.azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu
}

module "storage_account" {
  source                  = "./modules/storage_account"
  resource_group_name     = data.azurerm_resource_group.rg_eu.name
  location                = data.azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu

  eu_subnet_id           = module.virtual_network_eu.subnet_id
  us_vnet_id          = module.virtual_network_us.id
  eu_vnet_id          = module.virtual_network_eu.id

  whitelisted_ips = var.whitelisted_ips
}

# Upload scripts to blob storage

resource "azurerm_storage_blob" "bootstrapping_script" {
  name                   = "bootstrapping.ps1"
  storage_account_name   =  module.scripts_storage.name
  storage_container_name =  module.scripts_storage.scripts_container_name
  type                   = "Block"
  source                 =  "./scripts/bootstrapping.ps1"
  content_md5            = filemd5("./scripts/bootstrapping.ps1")
}

resource "azurerm_storage_blob" "create_service_script" {
  name                   = "create_service.ps1"
  storage_account_name   =  module.scripts_storage.name
  storage_container_name =  module.scripts_storage.scripts_container_name
  type                   = "Block"
  source                 =  "./scripts/create_service.ps1"

  content_md5            = filemd5("./scripts/create_service.ps1")
}

resource "time_sleep" "wait_after_blob_upload" {
  create_duration = "30s"

  triggers = {
    # Wait after the blob upload to ensure the blob is available
    create_service_md5 = azurerm_storage_blob.create_service_script.content_md5
    bootstrapping_md5  = azurerm_storage_blob.bootstrapping_script.content_md5
  }
}

 module "private_link" {
   source              = "./modules/private_link"
   resource_group_name = data.azurerm_resource_group.rg_eu.name
   resource_name_specifier = module.common_naming.resource_name_specifier_eu
   location            = data.azurerm_resource_group.rg_eu.location

   us_subnet_id           = module.virtual_network_us.subnet_id
   eu_subnet_id           = module.virtual_network_eu.subnet_id
   us_vnet_id          = module.virtual_network_us.id
   eu_vnet_id          = module.virtual_network_eu.id

   storage_account_id = module.storage_account.id
 }