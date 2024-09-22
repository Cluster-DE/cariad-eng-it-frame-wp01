output "name" {
  value = azurerm_storage_account.storage.name
}

output "scripts_container_name"{
    value = azurerm_storage_container.scripts.name
}
