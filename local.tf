# Locals for naming conventions and computed values
locals {
  service_code_akv = "AZKV"
  service_code_rg  = "RSG"

  # Use naming object if provided, otherwise fall back to individual variables
  region_code      = var.naming != null ? var.naming.region_code : var.region_code
  application_code = var.naming != null ? var.naming.application_code : var.application_code
  environment      = var.naming != null ? var.naming.environment : var.environment
  correlative      = var.naming != null ? var.naming.correlative : var.correlative
  objective_code   = var.naming != null ? var.naming.objective_code : var.objective_code

  resource_group_name = "${local.service_code_rg}${local.region_code}${local.application_code}${local.environment}${local.correlative}"
}