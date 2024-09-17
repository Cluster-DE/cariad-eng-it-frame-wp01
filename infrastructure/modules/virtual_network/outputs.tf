output "id" {
  value = azurerm_virtual_network.virtual_network.id
}

output "subnet_name"{
  value = local.subnet_resource_name
}

output "vnet_name"{
  value = local.vnet_resource_name
}