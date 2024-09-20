

data "azurerm_client_config" "current" {}

locals{
  eu_dns_zone_private_link_name = "eu"
  eu_dns_zone_private_link_resource_prefix = "pdz"
  eu_dns_zone_private_link_resource_name = "${local.eu_dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.eu_dns_zone_private_link_name}"

  us_dns_zone_private_link_name = "us"
  us_dns_zone_private_link_resource_prefix = "pdz"
  us_dns_zone_private_link_resource_name = "${local.us_dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.us_dns_zone_private_link_name}"
}


