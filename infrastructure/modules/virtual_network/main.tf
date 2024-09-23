locals {
  vnet_name            = "network"
  vnet_resource_prefix = "vnet"
  vnet_resource_name   = "${local.vnet_resource_prefix}${var.resource_name_specifier}${local.vnet_name}"

  subnet_name            = local.vnet_name
  subnet_resource_prefix = "snet"
  subnet_resource_name   = "${local.subnet_resource_prefix}${var.resource_name_specifier}${local.subnet_name}"

  nsg_name            = local.vnet_name
  nsg_resource_prefix = "nsg"
  nsg_resource_name   = "${local.nsg_resource_prefix}${var.resource_name_specifier}${local.nsg_name}"
}


# Firewall rules for the network security group. Allow RDP and SMB(Fileshare) traffic
resource "azurerm_network_security_group" "network_security_group" {
  name                = local.nsg_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSMB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
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
}

resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_resource_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = var.subnet_address_prefixes
}

# Associate the network security group with the subnet.
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}