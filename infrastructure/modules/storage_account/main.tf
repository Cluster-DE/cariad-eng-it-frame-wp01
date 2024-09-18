

data "azurerm_client_config" "current" {}

locals {
  storage_name            = "share"
  storage_resource_prefix = "st"
  storage_resource_name   = "${local.storage_resource_prefix}${var.resource_name_specifier}${local.storage_name}"

  fileshare_name            = "share"
  fileshare_resource_prefix = "fs"
  fileshare_resource_name   = "${local.fileshare_resource_prefix}${var.resource_name_specifier}${local.fileshare_name}"

  private_endpoint_name            = "share"
  private_endpoint_resource_prefix = "pe"
  private_endpoint_resource_name   = "${local.private_endpoint_resource_prefix}${var.resource_name_specifier}${local.private_endpoint_name}"

  private_service_connection_name            = "share"
  private_service_connection_resource_prefix = "psc"
  private_service_connection_resource_name   = "${local.private_service_connection_resource_prefix}${var.resource_name_specifier}${local.private_service_connection_name}"
}

resource "azurerm_storage_account" "storage" {
  name                     = local.storage_resource_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Premium"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.subnet_id]
  }
}

resource "azurerm_storage_share" "fileshare" {
  name                 = local.fileshare_resource_name
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 100
}


resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                = local.private_endpoint_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = local.private_service_connection_resource_name
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
}

resource "azurerm_private_dns_zone" "storage_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "eu_storage_dns_link" {
  name                  = "${local.storage_resource_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  virtual_network_id    = var.eu_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "us_storage_dns_link" {
  name                  = "${local.storage_resource_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  virtual_network_id    = var.us_vnet_id
}


resource "azurerm_private_dns_a_record" "storage_dns_record" {
  name                = azurerm_storage_account.storage.name
  zone_name           = azurerm_private_dns_zone.storage_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_private_endpoint.private_service_connection[0].private_ip_address]
}
