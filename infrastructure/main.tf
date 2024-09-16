resource "azurerm_resource_group" "rg_eu" {
  name     = "rg-${var.project_name}-${var.environment}-euw"
  location = "West Europe"
}

resource "azurerm_resource_group" "rg_us" {
  name     = "rg-${var.project_name}-${var.environment}-usw"
  location = "West US"
}