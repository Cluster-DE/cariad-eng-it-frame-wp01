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

variable "resource_name_specifier" {
  type        = string
  description = "Middle part of the resource name. Resource type is the prefix, resource name is the suffix"
}

variable "dns_zone_name"{
  type        = string
  description = "Name of the Blob DNS zone"
}

variable "client_number" {
  type        = number
  description = "Client number"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet, which the VMs will be connected to"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "storage_account_key" {
  type        = string
  description = "Key of the storage account"
}

variable "storage_account_connection_string" {
  type        = string
  description = "Connection string of the storage account"
}

variable "fileshare_name" {
  type        = string
  description = "Name of the fileshare"
}

variable "bootstrapping_script_name"{
  type        = string
  description = "Name of the bootstrapping script"
}

variable "create_service_script_name"{
  type        = string
  description = "Name of the script to create the service"
}

variable "scripts_container_name"{
  type        = string
  description = "Name of the container for the scripts"
}

variable "bootstrapping_md5"{
  type        = string
  description = "MD5 hash of the bootstrapping script file"
}

variable "create_service_md5"{
  type        = string
  description = "MD5 hash of the create service script file"
}

variable "key_vault_id"{
  type        = string
  description = "ID of the key vault"
}

variable "scripts_storage_account_name"{
  type        = string
  description = "Name of the storage account for the scripts"
}