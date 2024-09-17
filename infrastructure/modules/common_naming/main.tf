locals {
  # Middle part of the resource name. Resource type is the prefix, resource name is the suffix 
  resource_name_specifier_eu = "${var.environment}${var.project_short_name}${var.location_short_eu}"
  resource_name_specifier_us = "${var.environment}${var.project_short_name}${var.location_short_us}"
}
