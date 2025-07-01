# Simple working test for the Key Vault module
#
# Use case name: Simple Key Vault Test
# Description: Basic test example to validate the Key Vault module functionality with minimal configuration.
# When to use: Use this example to quickly test the module or as a starting point for development.
# Considerations:
#   - Creates a temporary resource group for testing
#   - Uses development environment configuration
#   - Minimal security configuration for testing purposes
#   - Suitable for development and testing environments only
# Variables used:
#   - location: Azure region for resource deployment (default: "East US 2")
#   - tenant_id: Retrieved automatically from current Azure context via data source
#   - region_code: Set to "EU2" for East US 2 region
#   - application_code: Set to "TEST" for testing purposes
#   - objective_code: Set to "KVLT" for Key Vault testing
#   - environment: Set to "D" for development environment
#   - correlative: Set to "01" for unique resource identification

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.28.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}


variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed"
  default     = "East US 2"
}


data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "../.."

  location         = var.location
  tenant_id        = data.azurerm_client_config.current.tenant_id
  region_code      = "EU2"
  application_code = "TEST"
  objective_code   = "KVLT"
  environment      = "D"
  correlative      = "01"
}

output "key_vault_name" {
  description = "The name of the created Key Vault"
  value       = module.key_vault.name
}

output "key_vault_id" {
  description = "The ID of the created Key Vault"
  value       = module.key_vault.id
}

output "key_vault_uri" {
  description = "The URI of the created Key Vault"
  value       = module.key_vault.uri
}
