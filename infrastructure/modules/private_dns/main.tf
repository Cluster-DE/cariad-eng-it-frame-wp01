

data "azurerm_client_config" "current" {}

locals{
  eu_dns_zone_private_link_name = "eu"
  eu_dns_zone_private_link_resource_prefix = "pdz"
  eu_dns_zone_private_link_resource_name = "${local.eu_dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.eu_dns_zone_private_link_name}"

  us_dns_zone_private_link_name = "us"
  us_dns_zone_private_link_resource_prefix = "pdz"
  us_dns_zone_private_link_resource_name = "${local.us_dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.us_dns_zone_private_link_name}"
}

resource "azurerm_private_dns_zone" "storage_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "eu_storage_dns_link" {
  name                  = local.eu_dns_zone_private_link_resource_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  virtual_network_id    = var.eu_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "us_storage_dns_link" {
  name                  = local.us_dns_zone_private_link_resource_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  virtual_network_id    = var.us_vnet_id
}

resource "azurerm_private_dns_a_record" "storage_dns_record" {
  name                = var.storage_account_name
  zone_name           = azurerm_private_dns_zone.storage_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.private_ip]
}