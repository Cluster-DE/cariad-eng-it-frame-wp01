

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
}

resource "azurerm_storage_account" "storage" {
  name                     = local.storage_resource_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "fileshare" {
  name                 = local.fileshare_resource_name
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 30

  depends_on = [
    azurerm_storage_account.storage,
    azurerm_role_assignment.storage_contributor, 
    azurerm_role_assignment.storage_smb_share_contributor]
}

resource "azurerm_private_dns_zone" "storage_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_storage_share.fileshare]
}

resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                = local.private_endpoint_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.eu_subnet_id

  private_service_connection {
    name                           = local.private_service_connection_resource_name
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false 
  }

    private_dns_zone_group {
    name                 = "dns-group-st"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_dns_zone.id]
  }

  depends_on = [azurerm_storage_share.fileshare]
}

resource "azurerm_private_dns_zone_virtual_network_link" "eu_storage_dns_link" {
  name                  = local.eu_dns_zone_private_link_resource_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  registration_enabled = true
  virtual_network_id    = var.eu_vnet_id

  depends_on = [azurerm_storage_share.fileshare]
}

resource "azurerm_private_dns_zone_virtual_network_link" "us_storage_dns_link" {
  name                  = local.us_dns_zone_private_link_resource_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zone.name
  registration_enabled = true
  virtual_network_id    = var.us_vnet_id

  depends_on = [azurerm_storage_share.fileshare]
}

resource "azurerm_private_dns_a_record" "dns_a_record" {
  name                = "a_record"
  zone_name           = azurerm_private_dns_zone.storage_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_private_endpoint.private_service_connection[0].private_ip_address]

  depends_on = [azurerm_storage_share.fileshare]
}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "storage_smb_share_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}