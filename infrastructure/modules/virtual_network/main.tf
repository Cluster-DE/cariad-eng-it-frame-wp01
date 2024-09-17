locals{
  vnet_name = "network"
  vnet_resource_prefix = "vnet"
  vnet_resource_name = "${local.vnet_resource_prefix}${var.resource_name_specifier}${local.vnet_name}"

  subnet_name = local.vnet_name
  subnet_resource_prefix = "snet"
  subnet_resource_name = "${local.subnet_resource_prefix}${var.resource_name_specifier}${local.subnet_name}"

  nsg_name = local.vnet_name
  nsg_resource_prefix = "nsg"
  nsg_resource_name = "${local.nsg_resource_prefix}${var.resource_name_specifier}${local.nsg_name}"
}

resource "azurerm_network_security_group" "network_security_group" {
  name                = local.nsg_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = local.vnet_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  subnet {
    name             = local.subnet_resource_name
    address_prefixes = var.subnet_address_prefixes
    security_group   = azurerm_network_security_group.network_security_group.id
  }
}