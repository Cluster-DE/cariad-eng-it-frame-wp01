variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "resource_name_specifier" {
  type        = string
  description = "Middle part of the resource name. Resource type is the prefix, resource name is the suffix"
}

variable "eu_subnet_id" {
  type        = string
  description = "EU subnet id"
}

variable "us_vnet_id" {
  type        = string
  description = "US virtual network id"
}

variable "eu_vnet_id" {
  type        = string
  description = "EU virtual network id"
}

variable "whitelisted_ips" {
  description = "List of IP addresses allowed to access the storage account"
  type        = list(string)
}

variable "principal_ids" {
  description = "List of principal ids to assign roles"
  type        = list(string)
}