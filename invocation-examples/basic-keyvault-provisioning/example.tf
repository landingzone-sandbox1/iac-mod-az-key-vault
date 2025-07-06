# =============================================================================
# COMPREHENSIVE AZURE KEY VAULT EXAMPLE
# =============================================================================
# Repository: https://github.com/landingzone-sandbox/iac-mod-az-key-vault
# Use case: Complete example showcasing the simplified interface of the Key Vault module
# Description: Demonstrates all major features including keys, secrets, RBAC, network ACLs, and private endpoints
# When to use: Use this as a reference for production Key Vault deployments with comprehensive security
# Considerations:
#   - Uses module-template pattern with location auto-mapping
#   - Demonstrates BCP naming conventions
#   - Shows least-privilege RBAC assignments
#   - Includes network security and private endpoints
#   - Production-ready configuration examples

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.28.0" # Match the module version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
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

# =============================================================================
# VARIABLES FOR EXAMPLES
# =============================================================================

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US 2"
}

variable "environment" {
  description = "Environment code"
  type        = string
  default     = "D"

  validation {
    condition     = contains(["D", "C", "P", "F"], var.environment)
    error_message = "Environment must be D (Development), C (Certification), P (Production), or F (Infrastructure)."
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}

# Generate random suffix for unique naming
resource "random_integer" "suffix" {
  min = 10
  max = 99
}

# =============================================================================
# RESOURCE GROUP FOR EXAMPLES
# =============================================================================

resource "azurerm_resource_group" "example" {
  name     = "RSG${local.region_code_examples}DEMO${var.environment}${format("%02d", random_integer.suffix.result)}"
  location = var.location

  tags = {
    Environment = var.environment == "P" ? "Production" : var.environment == "C" ? "Certification" : var.environment == "F" ? "Functional" : "Development"
    Purpose     = "Key Vault Module Examples"
    ManagedBy   = "terraform"
  }
}

locals {
  # Simple region mapping for examples
  region_code_examples = var.location == "East US" ? "EUS" : var.location == "East US 2" ? "EUS2" : var.location == "West US" ? "WUS" : var.location == "West US 2" ? "WUS2" : var.location == "Central US" ? "CUS" : var.location == "Canada Central" ? "CCAN" : var.location == "Brazil South" ? "BSOU" : "EUS2"
}

# =============================================================================
# EXAMPLE 1: BASIC KEY VAULT WITH RBAC
# =============================================================================

module "keyvault_basic" {
  source = "../.."

  location = var.location

  naming = {
    application_code = "FINC"
    environment      = var.environment
    correlative      = "01"
    objective_code   = "SEC"
  }

  keyvault_config = {
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Use the created resource group
    resource_group_name = azurerm_resource_group.example.name

    # Basic secure configuration
    sku_name                      = "premium"
    public_network_access_enabled = false
    purge_protection_enabled      = true
    soft_delete_retention_days    = 90

    # Network restrictions
    network_acls = {
      bypass         = "AzureServices"
      default_action = "Deny"
      ip_rules       = ["203.0.113.0/24"] # Example corporate IP range
    }

    # RBAC assignments for different roles
    rbac_assignments = {
      "current_user_admin" = {
        role_definition_id_or_name = "Key Vault Secrets Officer"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Current user - full secrets management"
      }
    }

    # Standard tags
    tags = {
      CostCenter     = "Finance"
      Application    = "Core Banking"
      SecurityLevel  = "High"
      BackupRequired = "true"
    }
  }
}

# =============================================================================
# EXAMPLE 2: KEY VAULT WITH KEYS AND SECRETS
# =============================================================================

module "keyvault_with_content" {
  source = "../.."

  location = var.location

  naming = {
    application_code = "APID"
    environment      = var.environment
    correlative      = format("%02d", random_integer.suffix.result + 1)
    objective_code   = "ENC"
  }

  keyvault_config = {
    tenant_id                      = data.azurerm_client_config.current.tenant_id
    resource_group_name            = azurerm_resource_group.example.name
    legacy_access_policies_enabled = false

    # Keys for encryption and signing
    keys = {
      "app-encryption-key" = {
        name     = "app-encryption-key"
        key_type = "RSA"
        key_size = 2048
        key_opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

        rotation_policy = {
          automatic = {
            time_after_creation = "P90D" # Rotate after 90 days
          }
          expire_after         = "P1Y"  # Expire after 1 year
          notify_before_expiry = "P30D" # Notify 30 days before expiry
        }
      }

      "api-signing-key" = {
        name     = "api-signing-key"
        key_type = "EC"
        curve    = "P-256"
        key_opts = ["sign", "verify"]
      }
    }

    # Application secrets
    secrets = {
      "database-connection-string" = {
        name         = "database-connection-string"
        value        = "Server=myserver.database.windows.net;Database=mydb;Trusted_Connection=true;"
        content_type = "connection-string"
      }

      "api-key-external-service" = {
        name            = "api-key-external-service"
        value           = "ak_test_51234567890abcdef..."
        content_type    = "api-key"
        expiration_date = "2025-12-31T23:59:59Z"
      }

      "jwt-signing-secret" = {
        name         = "jwt-signing-secret"
        value        = "super-secret-jwt-signing-key-change-in-production"
        content_type = "jwt-secret"
      }
    }

    # RBAC for application access
    rbac_assignments = {
      "app_secrets_access" = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Application read access to secrets"
      }

      "crypto_operations" = {
        role_definition_id_or_name = "Key Vault Crypto User"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Cryptographic operations access"
      }
    }

    # Resource lock
    lock = {
      kind = "CanNotDelete"
      name = "protect-keyvault"
    }

    tags = {
      Application = "API Gateway"
      DataClass   = "Internal"
      Environment = var.environment == "P" ? "Production" : "Development"
      HasSecrets  = "true"
      HasKeys     = "true"
    }
  }
}

# =============================================================================
# EXAMPLE 3: SIMPLE KEY VAULT FOR DEVELOPMENT
# =============================================================================

module "keyvault_simple" {
  source = "../.."

  location = var.location

  naming = {
    application_code = "DEMO"
    environment      = var.environment
    correlative      = format("%02d", random_integer.suffix.result + 2)
    objective_code   = "TST"
  }

  keyvault_config = {
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Minimal configuration for development
    sku_name                      = "standard"
    public_network_access_enabled = true  # Simplified for development
    purge_protection_enabled      = false # Disabled for easier cleanup in dev
    soft_delete_retention_days    = 7     # Minimum retention for dev

    # Simple RBAC assignment
    rbac_assignments = {
      "dev_access" = {
        role_definition_id_or_name = "Key Vault Secrets Officer"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Development access"
      }
    }

    tags = {
      Purpose = "Development Testing"
      Owner   = "Development Team"
    }
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "key_vault_basic_name" {
  description = "Name of the basic Key Vault"
  value       = module.keyvault_basic.name
}

output "key_vault_basic_uri" {
  description = "URI of the basic Key Vault"
  value       = module.keyvault_basic.uri
}

output "key_vault_with_content_name" {
  description = "Name of the Key Vault with content"
  value       = module.keyvault_with_content.name
}

output "key_vault_simple_name" {
  description = "Name of the simple Key Vault"
  value       = module.keyvault_simple.name
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.example.name
}

output "examples_summary" {
  description = "Summary of created Key Vaults and their purposes"
  value = {
    basic_keyvault = {
      name    = module.keyvault_basic.name
      purpose = "Financial services - high security with network restrictions"
      uri     = module.keyvault_basic.uri
    }
    content_keyvault = {
      name    = module.keyvault_with_content.name
      purpose = "API services - includes keys, secrets, and rotation policies"
      uri     = module.keyvault_with_content.uri
    }
    simple_keyvault = {
      name    = module.keyvault_simple.name
      purpose = "Development testing - minimal security for easy access"
      uri     = module.keyvault_simple.uri
    }
  }
}

output "azure_portal_links" {
  description = "Direct links to Key Vaults in Azure Portal"
  value = {
    basic_keyvault   = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${module.keyvault_basic.id}"
    content_keyvault = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${module.keyvault_with_content.id}"
    simple_keyvault  = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${module.keyvault_simple.id}"
  }
}

output "cli_commands" {
  description = "Useful Azure CLI commands for managing the Key Vaults"
  value = {
    basic_keyvault = {
      list_secrets = "az keyvault secret list --vault-name ${module.keyvault_basic.name}"
      set_secret   = "az keyvault secret set --vault-name ${module.keyvault_basic.name} --name 'my-secret' --value 'my-value'"
    }
    content_keyvault = {
      list_keys    = "az keyvault key list --vault-name ${module.keyvault_with_content.name}"
      list_secrets = "az keyvault secret list --vault-name ${module.keyvault_with_content.name}"
      get_secret   = "az keyvault secret show --vault-name ${module.keyvault_with_content.name} --name 'database-connection-string'"
      encrypt_data = "az keyvault key encrypt --vault-name ${module.keyvault_with_content.name} --name 'app-encryption-key' --algorithm 'RSA-OAEP' --value 'Hello World'"
    }
    simple_keyvault = {
      set_test_secret = "az keyvault secret set --vault-name ${module.keyvault_simple.name} --name 'test-secret' --value 'test-value'"
      list_secrets    = "az keyvault secret list --vault-name ${module.keyvault_simple.name}"
    }
  }
}

output "naming_convention_examples" {
  description = "Examples of BCP naming convention used"
  value = {
    explanation = "BCP Pattern: {ServiceCode}{RegionCode}{ApplicationCode}{ObjectiveCode}{Environment}{Correlative}"
    examples = {
      basic_keyvault   = "AZKV + ${local.region_code_examples} + FINC + SEC + ${var.environment} + ${format("%02d", random_integer.suffix.result)}"
      content_keyvault = "AZKV + ${local.region_code_examples} + APID + ENC + ${var.environment} + ${format("%02d", random_integer.suffix.result + 1)}"
      simple_keyvault  = "AZKV + ${local.region_code_examples} + DEMO + TST + ${var.environment} + ${format("%02d", random_integer.suffix.result + 2)}"
    }
  }
}
