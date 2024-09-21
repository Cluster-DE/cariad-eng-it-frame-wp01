

data "azurerm_client_config" "current" {}

locals{
  private_service_connection_name            = "share"
  private_service_connection_resource_prefix = "psc"
  private_service_connection_resource_name = "${local.private_service_connection_resource_prefix}${var.resource_name_specifier}${local.private_service_connection_name}"

  dns_zone_private_link_name = "share"
  dns_zone_private_link_resource_prefix = "pdz"
  dns_zone_private_link_resource_name = "${local.dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.dns_zone_private_link_name}"

  eu_dns_zone_private_link_name = "eu"
  eu_dns_zone_private_link_resource_prefix = "pdz"
  eu_dns_zone_private_link_resource_name = "${local.eu_dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.eu_dns_zone_private_link_name}"

  us_dns_zone_private_link_name = "us"
  us_dns_zone_private_link_resource_prefix = "pdz"
  us_dns_zone_private_link_resource_name = "${local.us_dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.us_dns_zone_private_link_name}"

  private_endpoint_name            = "share"
  private_endpoint_resource_prefix = "pe"
  private_endpoint_resource_name = "${local.private_endpoint_resource_prefix}${var.resource_name_specifier}${local.private_endpoint_name}"
}


 resource "azurerm_private_dns_zone" "storage_dns_zone" {
   name                = "privatelink.file.core.windows.net"
   resource_group_name = var.resource_group_name
 }

 resource "azurerm_private_endpoint" "storage_private_endpoint" {
   name                = local.private_endpoint_resource_name
   location            = var.location
   resource_group_name = var.resource_group_name
   subnet_id           = var.eu_subnet_id

   private_service_connection {
     name                           = local.private_service_connection_resource_name
     private_connection_resource_id = var.storage_account_id
     subresource_names              = ["file"]
     is_manual_connection           = false 
   }
 }

 resource "azurerm_private_dns_zone_virtual_network_link" "eu_storage_dns_link" {
   name                  = local.eu_dns_zone_private_link_resource_name
   resource_group_name   = var.resource_group_name
   private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
   registration_enabled = false
   virtual_network_id    = var.eu_vnet_id
 }

 resource "azurerm_private_dns_zone_virtual_network_link" "us_storage_dns_link" {
   name                  = local.us_dns_zone_private_link_resource_name
   resource_group_name   = var.resource_group_name
   private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
   registration_enabled = true
   virtual_network_id    = var.us_vnet_id
 }

 resource "azurerm_private_dns_a_record" "dns_a_record" {
   name                = "a_record"
   zone_name           = azurerm_private_dns_zone.storage_dns_zone.name
   resource_group_name = var.resource_group_name
   ttl                 = 300
   records             = [azurerm_private_endpoint.storage_private_endpoint.private_service_connection[0].private_ip_address]
 }