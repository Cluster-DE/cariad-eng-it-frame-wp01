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

variable "principal_ids"{
  type = list(string)
  description = "Principal IDs that are able to administer the resources"
}