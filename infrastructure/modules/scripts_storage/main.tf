

data "azurerm_client_config" "current" {}

locals {
  storage_name            = "scripts"
  storage_resource_prefix = "st"
  storage_resource_name   = "${local.storage_resource_prefix}${var.resource_name_specifier}${local.storage_name}"
}

# Storage account for storing scripts, which then are downloaded by a VM-Extension
resource "azurerm_storage_account" "storage" {
  name                     = local.storage_resource_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = true
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  =  azurerm_storage_account.storage.name
  container_access_type = "container"
}

# Assign Storage Account Contributor role to all user/service principals listed in var.principal_ids
resource "azurerm_role_assignment" "storage_contributor" {
  for_each = toset(var.principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = each.value
}

# Assign Storage Blob Data Contributor role to all user/service principals listed in var.principal_ids
resource "azurerm_role_assignment" "blob_data_contributor" {
  for_each = toset(var.principal_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}