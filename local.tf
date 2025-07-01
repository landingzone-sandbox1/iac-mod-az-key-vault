# Locals for naming conventions and computed values
locals {
  service_code_akv = "AZKV"
  service_code_rg  = "RSG"
  region_code      = var.region_code
  application_code = var.application_code
  environment      = var.environment
  correlative      = var.correlative

  resource_group_name = "${local.service_code_rg}${local.region_code}${local.application_code}${local.environment}${local.correlative}"
}