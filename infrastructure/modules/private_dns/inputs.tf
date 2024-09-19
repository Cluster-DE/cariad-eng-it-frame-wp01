variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_name_specifier"{
  type        = string
  description = "Middle part of the resource name. Resource type is the prefix, resource name is the suffix"
}

variable "us_subnet_id" {
  type        = string
  description = "US subnet id"
}

variable "eu_subnet_id" {
  type        = string
  description = "EU subnet id"
}

variable "us_vnet_id"{
  type        = string
  description = "US virtual network id"
}

variable "eu_vnet_id"{
  type        = string
  description = "EU virtual network id"
}

variable "private_ip" {
  type        = string
  description = "Private IP address"
}

variable "storage_account_name"{
  type        = string
  description = "Name of the storage account"
}