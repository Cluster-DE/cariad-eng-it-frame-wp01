

data "azurerm_client_config" "current" {}

locals{
  storage_name = "share"
  storage_resource_prefix = "st"
  storage_resource_name = "${local.storage_resource_prefix}${var.resource_name_specifier}${local.storage_name}"

  fileshare_name = "share"
  fileshare_resource_prefix = "fs"
  fileshare_resource_name = "${local.fileshare_resource_prefix}${var.resource_name_specifier}${local.fileshare_name}"

  private_endpoint_name = "share"
  private_endpoint_resource_prefix = "pe"
  private_endpoint_resource_name = "${local.private_endpoint_resource_prefix}${var.resource_name_specifier}${local.private_endpoint_name}"

  private_service_connection_name = "share"
  private_service_connection_resource_prefix = "psc"
  private_service_connection_resource_name = "${local.private_service_connection_resource_prefix}${var.resource_name_specifier}${local.private_service_connection_name}"

  dns_zone_private_link_name = "share"
  dns_zone_private_link_resource_prefix = "pdz"
  dns_zone_private_link_resource_name = "${local.dns_zone_private_link_resource_prefix}${var.resource_name_specifier}${local.dns_zone_private_link_name}"
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
  quota                = 100
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
}