output "name"{
    value = azurerm_storage_account.storage.name
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