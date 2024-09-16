resource "azurerm_network_security_group" "network_security_group" {
  name                = "nsg-${var.project_name}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "vnet-${var.project_name}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  subnet {
    name             = var.subnet_name
    address_prefixes = var.subnet_address_prefixes
    security_group   = azurerm_network_security_group.network_security_group.id
  }
}