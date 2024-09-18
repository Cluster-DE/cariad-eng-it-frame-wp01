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

variable "address_space" {
  type        = list(string)
  description = "Address space of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "subnet name"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "subnet address prefixes"
}