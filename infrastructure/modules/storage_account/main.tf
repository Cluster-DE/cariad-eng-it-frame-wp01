

data "azurerm_client_config" "current" {}

locals {
  storage_name            = "share"
  storage_resource_prefix = "st"
  storage_resource_name   = "${local.storage_resource_prefix}${var.resource_name_specifier}${local.storage_name}"

  fileshare_name            = "share"
  fileshare_resource_prefix = "fs"
  fileshare_resource_name   = "${local.fileshare_resource_prefix}${var.resource_name_specifier}${local.fileshare_name}"
}

resource "azurerm_storage_account" "storage" {
  name                     = local.storage_resource_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = true

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.whitelisted_ips
  }
}

resource "azurerm_storage_share" "fileshare" {
  name                 = local.fileshare_resource_name
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 30
}

resource "azurerm_role_assignment" "storage_contributor" {
  for_each = toset(var.principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "storage_smb_share_contributor" {
  for_each = toset(var.principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = each.value
}