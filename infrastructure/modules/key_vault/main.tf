

data "azurerm_client_config" "current" {}

locals {
  keyvault_name            = "secrets"
  keyvault_resource_prefix = "kv"
  keyvault_resource_name   = "${local.keyvault_resource_prefix}${var.resource_name_specifier}${local.keyvault_name}"
}

resource "azurerm_key_vault" "kv" {
  name                        = local.keyvault_resource_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  
  enable_rbac_authorization = true

  sku_name = "standard"
}

# Assign Key Vault Administrator role to the current user/service principal
resource "azurerm_role_assignment" "key_vault_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign Key Vault Secrets User role to the current user/service principal
resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}