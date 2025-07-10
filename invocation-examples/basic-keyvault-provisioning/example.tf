# =============================================================================
# Use case name: Basic Azure Key Vault Provisioning for Development Environment
# Description: Example showing how to provision a basic Azure Key Vault with RBAC, 
#              secrets, and keys for development teams using the BCP naming conventions
# When to apply it: Use this example when setting up a development Key Vault with 
#                   basic security features and sample content
# Considerations: 
#   - Requires Azure authentication and appropriate permissions
#   - Uses BCP naming conventions for resource identification
#   - Creates a new resource group if none is specified
#   - Demonstrates least-privilege RBAC assignments
#   - Includes sample secrets and keys for testing
# Variables used:
#   - location: Azure region for deployment (maps to BCP region code)
#   - environment: Environment code (D=Development, C=Certification, P=Production, F=Functional)
# =============================================================================

terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.28"
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
# VARIABLES
# =============================================================================

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Name of an existing Azure resource group to deploy the Key Vault into. Must be created outside this example."
  type        = string
}

variable "environment" {
  description = "Environment code (D=Development, C=Certification, P=Production, F=Functional)"
  type        = string
  default     = "D"

  validation {
    condition     = contains(["D", "C", "P", "F"], var.environment)
    error_message = "Environment must be D (Development), C (Certification), P (Production), or F (Functional)."
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get current Azure client configuration for auto-detection
data "azurerm_client_config" "current" {}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  # BCP Naming Convention Components
  application_code = "FINC" # Finance application
  objective_code   = "SEC"  # Security/Key Vault purpose
  correlative      = "01"   # First instance

  # Region mapping for BCP naming (from auto.tfvars location)
  region_code_mapping = {
    "East US"        = "EU1"
    "East US 2"      = "EU2"
    "Central US"     = "CU1"
    "West US"        = "WU1"
    "West US 2"      = "WU2"
    "Canada Central" = "CC1"
    "Brazil South"   = "BS1"
  }

  region_code = local.region_code_mapping[var.location]

  # Corporate Network Configuration
  corporate_ip_ranges = [
    "203.0.113.0/24", # Example corporate network
    "198.51.100.0/24" # Example branch office network
  ]

  # Key Vault Sample Content
  sample_secrets = {
    "database-connection-string" = {
      name            = "database-connection-string"
      value           = "Server=sqlserver.example.com;Database=app;User Id=user;Password=password;"
      content_type    = "text/plain"
      expiration_date = "2025-12-31T23:59:59Z"
    }
    "api-key" = {
      name            = "api-key"
      value           = "super-secret-api-key-value"
      content_type    = "text/plain"
      expiration_date = "2025-12-31T23:59:59Z"
    }
  }

  sample_keys = {
    "encryption-key" = {
      name     = "encryption-key"
      key_type = "RSA"
      key_size = 2048
      key_opts = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
    }
  }

  # RBAC Configuration
  current_user_principal_id = data.azurerm_client_config.current.object_id
}

# =============================================================================
# BASIC KEY VAULT WITH RBAC AND CONTENT
# =============================================================================

module "keyvault_basic" {
  source = "../.."

  location = var.location

  naming = {
    application_code = local.application_code
    objective_code   = local.objective_code
    environment      = var.environment
    correlative      = local.correlative
  }

  keyvault_config = {
    resource_group_name = var.resource_group_name

    # Auto-detect tenant ID from current context
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Basic secure configuration appropriate for development
    sku_name                        = "standard" # Standard SKU for development
    public_network_access_enabled   = false      # Private access only
    purge_protection_enabled        = true       # Prevent accidental purge
    soft_delete_retention_days      = 90         # 90-day retention
    enabled_for_disk_encryption     = true       # Allow disk encryption
    enabled_for_deployment          = false      # No VM certificate access needed
    enabled_for_template_deployment = false      # No ARM template access needed

    # Network restrictions with corporate IP ranges
    network_acls = {
      bypass         = "AzureServices"           # Allow Azure services
      default_action = "Deny"                    # Deny all other access
      ip_rules       = local.corporate_ip_ranges # Corporate networks only
    }

    # RBAC assignments for current user with least-privilege access
    role_assignments = {
      "current_user_secrets_officer" = {
        role_definition_id_or_name = "Key Vault Secrets Officer"
        principal_id               = local.current_user_principal_id
        principal_type             = "User"
        description                = "Current user - full secrets management for development"
      }
      "current_user_crypto_user" = {
        role_definition_id_or_name = "Key Vault Crypto User"
        principal_id               = local.current_user_principal_id
        principal_type             = "User"
        description                = "Current user - cryptographic operations for development"
      }
    }

    # Sample secrets for development/testing
    secrets = local.sample_secrets

    # Sample keys for development/testing
    keys = local.sample_keys

    # Resource lock for protection
    lock = {
      kind = "CanNotDelete"
      name = "lock-${local.application_code}-${local.objective_code}-${var.environment}"
    }

    # Standard tags
    tags = {
      CostCenter     = "Finance"
      Application    = "Core Banking Development"
      SecurityLevel  = "Medium"
      BackupRequired = "true"
      Owner          = "Development Team"
    }
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "keyvault_info" {
  description = "Key Vault information for development team"
  value = {
    name                = module.keyvault_basic.resource.name
    id                  = module.keyvault_basic.resource.id
    vault_uri           = module.keyvault_basic.resource.uri
    resource_group_name = var.resource_group_name
    location            = var.location
  }
}

output "rbac_assignments" {
  description = "RBAC assignments created for the Key Vault (not available: module does not export this output)"
  value       = "Not available: The module does not export rbac_role_assignments. See module documentation."
}

output "security_compliance" {
  description = "Security compliance status"
  value       = module.keyvault_basic.security_compliance_status
}
