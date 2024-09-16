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
  location_short      = "euw"
  project_name        = var.project_name
  environment         = var.environment
  address_space       = ["10.1.0.0/16"]
  subnet_name         = "subnet"
  subnet_address_prefixes = ["10.1.1.0/24"]
}

module "virtual_network_us" {
  source              = "./modules/virtual_network"
  resource_group_name = azurerm_resource_group.rg_us.name
  location            = azurerm_resource_group.rg_us.location
  location_short      = "usw"
  project_name        = var.project_name
  environment         = var.environment
  address_space       = ["10.2.0.0/16"]
  subnet_name         = "subnet"
  subnet_address_prefixes = ["10.2.1.0/24"]
}

resource "azurerm_virtual_network_peering" "eu-to-us" {
  name                      = "peer-${var.project_name}-${var.environment}-euw"
  resource_group_name       = azurerm_resource_group.rg_eu.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_eu.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_us.id
}

resource "azurerm_virtual_network_peering" "us-to-eu" {
  name                      = "peer-${var.project_name}-${var.environment}-usw"
  resource_group_name       = azurerm_resource_group.rg_us.name
  virtual_network_name      = azurerm_virtual_network.virtual_network_us.name
  remote_virtual_network_id = azurerm_virtual_network.virtual_network_eu.id
}