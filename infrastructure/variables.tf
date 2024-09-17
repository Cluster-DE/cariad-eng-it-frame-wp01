variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "project_short_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment of the resource group"
}

variable "location_short_eu"{
  type      = string
  description = "Short version of location of the resource group for EU"
}

variable "location_short_us"{
  type      = string
  description = "Short version of location of the resource group for US"
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID"
}