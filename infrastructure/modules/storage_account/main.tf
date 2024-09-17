

data "azurerm_client_config" "current" {}

locals{
  storage_name = "share"
  storage_resource_prefix = "st"
  storage_resource_name = "${local.storage_resource_prefix}${var.resource_name_specifier}${local.storage_name}"

  fileshare_name = "share"
  fileshare_resource_prefix = "fs"
  fileshare_resource_name = "${local.fileshare_resource_prefix}${var.resource_name_specifier}${local.fileshare_name}"
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
  quota                = 50  # Quota in GB
}
