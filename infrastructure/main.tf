terraform {
  backend "azurerm" {
    resource_group_name   = "rg-cariad-frame-tf-state"
    storage_account_name  = "sacariadframetfstate"
    container_name        = "tfstate"
    key                   = "dev.tfstate"
  }
}

module "common_naming" {
  source              = "./modules/common_naming"
  location_short_eu      = var.location_short_eu
  location_short_us      = var.location_short_us
  project_short_name  = var.project_short_name
  environment         = var.environment
}

resource "azurerm_resource_group" "rg_eu" {
  name     = "rg-${var.project_name}-${var.environment}-euw"
  location = "West Europe"
}

resource "azurerm_resource_group" "rg_us" {
  name     = "rg-${var.project_name}-${var.environment}-usw"
  location = "West US"
}

module "virtual_network_eu" {
  source              = "./modules/virtual_network"
  resource_group_name = azurerm_resource_group.rg_eu.name
  location            = azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu
  address_space       = ["10.1.0.0/16"]
  subnet_name         = "subnet"
  subnet_address_prefixes = ["10.1.1.0/24"]
}

module "virtual_network_us" {
  source              = "./modules/virtual_network"
  resource_group_name = azurerm_resource_group.rg_us.name
  location            = azurerm_resource_group.rg_us.location
  resource_name_specifier = module.common_naming.resource_name_specifier_us
  address_space       = ["10.2.0.0/16"]
  subnet_name         = "subnet"
  subnet_address_prefixes = ["10.2.1.0/24"]
}

resource "azurerm_virtual_network_peering" "eu-to-us" {
  name                      = "peer-${var.project_name}-${var.environment}-euw"
  resource_group_name       = azurerm_resource_group.rg_eu.name
  virtual_network_name      = module.virtual_network_eu.vnet_name
  remote_virtual_network_id = module.virtual_network_us.id
}

resource "azurerm_virtual_network_peering" "us-to-eu" {
  name                      = "peer-${var.project_name}-${var.environment}-usw"
  resource_group_name       = azurerm_resource_group.rg_us.name
  virtual_network_name      = module.virtual_network_us.vnet_name
  remote_virtual_network_id = module.virtual_network_eu.id
}

module "key_vault" {
  source              = "./modules/key_vault"
  resource_group_name = azurerm_resource_group.rg_eu.name
  location            = azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu
}

module "vm_client1" {
  source              = "./modules/vm_client"
  resource_group_name_eu = azurerm_resource_group.rg_eu.name
  resource_group_name_us = azurerm_resource_group.rg_us.name
  location            = azurerm_resource_group.rg_us.location
  resource_name_specifier = module.common_naming.resource_name_specifier_us
  client_number       = 1
  vnet_name           = module.virtual_network_us.vnet_name
  subnet_name         = module.virtual_network_us.subnet_name
  
  key_vault_name      = module.key_vault.name

  storage_account_name = module.storage_account.name
  storage_account_key  = module.storage_account.key
  fileshare_name       = module.storage_account.fileshare_name

  depends_on = [
    azurerm_virtual_network_peering.eu-to-us, 
    azurerm_virtual_network_peering.us-to-eu, 
    module.virtual_network_eu, 
    module.virtual_network_us
    ]
}

module "vm_client2"{
  source              = "./modules/vm_client"
  resource_group_name_eu = azurerm_resource_group.rg_eu.name
  resource_group_name_us = azurerm_resource_group.rg_us.name
  location            = azurerm_resource_group.rg_us.location
  resource_name_specifier = module.common_naming.resource_name_specifier_us
  client_number       = 2
  vnet_name           = module.virtual_network_us.vnet_name
  subnet_name         = module.virtual_network_us.subnet_name
  key_vault_name      = module.key_vault.name

  storage_account_name = module.storage_account.name
  storage_account_key  = module.storage_account.key
  fileshare_name       = module.storage_account.fileshare_name


  depends_on = [
    azurerm_virtual_network_peering.eu-to-us, 
    azurerm_virtual_network_peering.us-to-eu, 
    module.virtual_network_eu, 
    module.virtual_network_us   
    ]
} 

module "storage_account" {
  source              = "./modules/storage_account"
  resource_group_name = azurerm_resource_group.rg_eu.name
  location            = azurerm_resource_group.rg_eu.location
  resource_name_specifier = module.common_naming.resource_name_specifier_eu
}