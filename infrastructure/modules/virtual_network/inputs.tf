variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "location_short" {
  type        = string
  description = "Short version of location of the resource group"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment of the resource group"
}

variable "address_space" {
  type        = list(string)
  description = "Address space of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "subnet name"
}