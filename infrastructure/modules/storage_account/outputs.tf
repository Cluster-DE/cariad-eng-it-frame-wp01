output "name"{
    value = azurerm_storage_account.storage.name
}

output "private_domain"{
    value = "${azurerm_storage_account.storage.name}.${azurerm_private_dns_zone.storage_dns_zone.name}"
}

output "key"{
    value = azurerm_storage_account.storage.primary_access_key
}

output "fileshare_name"{
    value = azurerm_storage_share.fileshare.name
}

output "connection_string"{
    value = azurerm_storage_account.storage.primary_connection_string
}