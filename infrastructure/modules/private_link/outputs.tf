output "file_dns_zone_name" {
  value = azurerm_private_dns_zone.file_dns_zone.name
}

output "blob_dns_zone_name" {
  value = azurerm_private_dns_zone.blob_dns_zone.name
}