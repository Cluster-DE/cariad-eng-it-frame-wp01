variable "resource_group_name_eu" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_group_name_us" {
  type        = string
  description = "Name of the resource group"
}


variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "resource_name_specifier"{
  type        = string
  description = "Middle part of the resource name. Resource type is the prefix, resource name is the suffix"
}

variable "client_number"{
  type        = number
  description = "Client number"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network, which the VMs will be connected to"
}

variable "subnet_name" {
  type        = string
  description = "subnet name"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the key vault"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "storage_account_key" {
  type        = string
  description = "Key of the storage account"
}

variable "fileshare_name" {
  type        = string
  description = "Name of the fileshare"
}