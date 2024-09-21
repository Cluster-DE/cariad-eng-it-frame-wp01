output "name" {
  value = azurerm_storage_account.storage.name
}

output "key"{
    value = azurerm_storage_account.storage.primary_access_key
}

output "fileshare_name" {
  value = azurerm_storage_share.fileshare.name
}

output "connection_string"{
    value = azurerm_storage_account.storage.primary_connection_string
}

output "scripts_container_name"{
    value = azurerm_storage_container.scripts.name
}

# output "private_ip"{
#     value = azurerm_private_endpoint.storage_private_endpoint.private_service_connection.0.private_ip_address
# }

# output "private_domain"{
#     value = "${local.storage_resource_name}.privatelink.file.core.windows.net"
# }