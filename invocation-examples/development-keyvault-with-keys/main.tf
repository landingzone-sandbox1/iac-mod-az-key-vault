# =============================================================================
# Use case name: Development Key Vault with Cryptographic Keys
# Description: Example showing how to provision a development Azure Key Vault
#              with cryptographic keys for encryption, signing, and testing scenarios.
# 
# When to apply it:
#   - Development and testing environments
#   - Applications requiring cryptographic operations (encrypt/decrypt, sign/verify)
#   - Proof of concept scenarios with key management
#   - Learning and experimentation with Azure Key Vault features
# 
# Considerations:
#   - Standard SKU sufficient for development workloads
#   - Public network access enabled for easier development access
#   - Key rotation policies configured for learning purposes
#   - Less restrictive network policies for development convenience
#   - Resource locks disabled for easy cleanup
# 
# Variables used:
#   - application_code: "DEMO" - Demo application identifier
#   - objective_code: "KVLT" - Key Vault resource type identifier
#   - environment: "D" - Development environment designation
#   - correlative: "01" - First instance of this resource type
#   - tenant_id: Azure AD tenant for authentication
#   - encryption_keys: RSA and EC keys for different cryptographic operations
#   - development_secrets: Non-sensitive development configuration
# =============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Local variables for this example
locals {
  # Development-specific configuration
  app_name = "demo-application"
  team     = "development"

  # Development keys for different scenarios
  crypto_keys = {
    "rsa-encryption-key" = {
      name     = "rsa-encryption-key"
      key_type = "RSA"
      key_size = 2048
      key_opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

      # Key rotation policy for learning
      rotation_policy = {
        expire_after         = "P365D" # 1 year
        notify_before_expiry = "P30D"  # 30 days before expiry
        automatic = {
          time_before_expiry = "P30D" # Auto-rotate 30 days before expiry
        }
      }

      tags = {
        Purpose = "Encryption"
        KeyType = "RSA-2048"
      }
    }

    "ec-signing-key" = {
      name     = "ec-signing-key"
      key_type = "EC"
      curve    = "P-256"
      key_opts = ["sign", "verify"]

      tags = {
        Purpose = "Digital Signature"
        KeyType = "EC-P256"
      }
    }

    "hsm-test-key" = {
      name     = "hsm-test-key"
      key_type = "RSA-HSM"
      key_size = 2048
      key_opts = ["encrypt", "decrypt", "sign", "verify"]

      tags = {
        Purpose = "HSM Testing"
        KeyType = "RSA-HSM-2048"
      }
    }
  }

  # Development secrets (non-sensitive)
  dev_secrets = {
    "dev-api-endpoint" = {
      name         = "dev-api-endpoint"
      value        = "https://api-dev.example.com"
      content_type = "text/plain"
    }
    "dev-database-name" = {
      name         = "dev-database-name"
      value        = "demo_app_dev"
      content_type = "text/plain"
    }
  }
}

# Main Key Vault module invocation
module "development_keyvault" {
  source = "../../" # Path to the Key Vault module

  # 1. Location - Auto-maps to region code (WUS2)
  location = "West US 2"

  # 2. Naming convention following BCP standards
  naming = {
    application_code = "DEMO" # Demo Application
    objective_code   = "KVLT" # Key Vault
    environment      = "D"    # Development
    correlative      = "01"   # First instance
  }

  # 3. Complete Key Vault configuration
  keyvault_config = {
    # Required: Azure tenant ID
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Standard SKU for development (cost-effective)
    sku_name = "standard"

    # Development-friendly security configuration
    enabled_for_deployment          = true  # Allow VM deployment for testing
    enabled_for_disk_encryption     = true  # Allow disk encryption
    enabled_for_template_deployment = true  # Allow ARM template access
    public_network_access_enabled   = true  # Public access for development
    purge_protection_enabled        = false # Allow easy cleanup
    soft_delete_retention_days      = 7     # Minimum retention for dev

    # More permissive network access for development
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Allow" # Allow access for easier development
      ip_rules                   = []
      virtual_network_subnet_ids = []
    }

    # RBAC assignments for development team
    role_assignments = {
      # Current user gets admin access for development
      "dev-admin" = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Development admin access"
      }

      # Developer access to crypto operations
      "dev-crypto-user" = {
        role_definition_id_or_name = "Key Vault Crypto User"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Development crypto operations access"
      }
    }

    # Cryptographic keys for development scenarios
    keys = local.crypto_keys

    # Development secrets
    secrets = local.dev_secrets

    # No resource lock for easy development cleanup
    # lock = null  (commented out)

    # Tags for resource management
    tags = {
      Environment       = "Development"
      Application       = local.app_name
      Team              = local.team
      Purpose           = "Learning and Development"
      CostCenter        = "DEV-001"
      AutoShutdown      = "true"
      TemporaryResource = "true"
    }
  }
}

# Outputs for development use
output "keyvault_id" {
  description = "The ID of the development Key Vault"
  value       = module.development_keyvault.key_vault_id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault for application configuration"
  value       = module.development_keyvault.key_vault_uri
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = module.development_keyvault.key_vault_name
}

output "available_keys" {
  description = "List of keys created for development testing"
  value = {
    for key_name, key_config in local.crypto_keys : key_name => {
      name     = key_config.name
      key_type = key_config.key_type
      purpose  = key_config.tags.Purpose
    }
  }
}

# Example of how to use the keys in application code (for documentation)
output "usage_examples" {
  description = "Example usage patterns for the created keys"
  value = {
    encryption_example = "Use 'rsa-encryption-key' for encrypting sensitive data"
    signing_example    = "Use 'ec-signing-key' for creating digital signatures"
    hsm_example        = "Use 'hsm-test-key' for hardware security module operations"
  }
}
