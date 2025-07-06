# =============================================================================
# Use case name: Legacy Key Vault with Access Policies for Migration Scenarios
# Description: Example showing how to provision an Azure Key Vault using legacy
#              access policies for backwards compatibility during RBAC migration.
# 
# When to apply it:
#   - Migrating from legacy Key Vault access policies to RBAC
#   - Existing applications not yet compatible with RBAC model
#   - Gradual migration scenarios requiring both access models
#   - Legacy systems requiring specific permission combinations
#   - Testing and validation during RBAC migration
# 
# Considerations:
#   - Legacy access policies and RBAC cannot be used simultaneously
#   - Access policies provide granular permissions but are harder to manage
#   - Service principals and user object IDs must be known in advance
#   - Migration to RBAC is recommended for better security and management
#   - This pattern should be temporary during migration periods
# 
# Variables used:
#   - application_code: "LGCY" - Legacy application identifier
#   - objective_code: "KVLT" - Key Vault resource type identifier
#   - environment: "C" - Certification environment designation
#   - correlative: "01" - First instance of this resource type
#   - tenant_id: Azure AD tenant for authentication
#   - object_ids: User and service principal object IDs for access policies
#   - access_policies: Granular permissions for different principals
# =============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Local variables for this example
locals {
  # Legacy application configuration
  app_name = "legacy-application"
  team     = "legacy-systems"

  # Object IDs for access policies (replace with actual values)
  principals = {
    legacy_app_service_principal = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"       # Legacy app service principal
    admin_user                   = data.azurerm_client_config.current.object_id # Current user
    backup_service_principal     = "bbbbbbbb-cccc-dddd-eeee-ffffffffffff"       # Backup service
    monitoring_app               = "cccccccc-dddd-eeee-ffff-aaaaaaaaaaaa"       # Monitoring application
  }

  # Legacy access policies with granular permissions
  access_policies = {
    # Legacy application - needs secrets and keys
    "legacy-app-access" = {
      object_id = local.principals.legacy_app_service_principal

      key_permissions = [
        "Get",
        "List",
        "Decrypt",
        "Encrypt",
        "UnwrapKey",
        "WrapKey",
        "Verify",
        "Sign"
      ]

      secret_permissions = [
        "Get",
        "List",
        "Set" # Can create/update secrets
      ]

      certificate_permissions = [
        "Get",
        "List"
      ]

      storage_permissions = []
    }

    # Administrator - full permissions
    "admin-full-access" = {
      object_id = local.principals.admin_user

      key_permissions = [
        "Backup",
        "Create",
        "Decrypt",
        "Delete",
        "Encrypt",
        "Get",
        "Import",
        "List",
        "Purge",
        "Recover",
        "Restore",
        "Sign",
        "UnwrapKey",
        "Update",
        "Verify",
        "WrapKey"
      ]

      secret_permissions = [
        "Backup",
        "Delete",
        "Get",
        "List",
        "Purge",
        "Recover",
        "Restore",
        "Set"
      ]

      certificate_permissions = [
        "Backup",
        "Create",
        "Delete",
        "DeleteIssuers",
        "Get",
        "GetIssuers",
        "Import",
        "List",
        "ListIssuers",
        "ManageContacts",
        "ManageIssuers",
        "Purge",
        "Recover",
        "Restore",
        "SetIssuers",
        "Update"
      ]

      storage_permissions = [
        "Backup",
        "Delete",
        "DeleteSAS",
        "Get",
        "GetSAS",
        "List",
        "ListSAS",
        "Purge",
        "Recover",
        "RegenerateKey",
        "Restore",
        "Set",
        "SetSAS",
        "Update"
      ]
    }

    # Backup service - read and backup permissions only
    "backup-service-access" = {
      object_id = local.principals.backup_service_principal

      key_permissions = [
        "Get",
        "List",
        "Backup"
      ]

      secret_permissions = [
        "Get",
        "List",
        "Backup"
      ]

      certificate_permissions = [
        "Get",
        "List",
        "Backup"
      ]

      storage_permissions = [
        "Get",
        "List",
        "Backup"
      ]
    }

    # Monitoring application - read-only access
    "monitoring-read-access" = {
      object_id = local.principals.monitoring_app

      key_permissions = [
        "Get",
        "List"
      ]

      secret_permissions = [
        "Get",
        "List"
      ]

      certificate_permissions = [
        "Get",
        "List"
      ]

      storage_permissions = []
    }
  }

  # Legacy application secrets
  legacy_secrets = {
    "legacy-database-connection" = {
      name  = "legacy-database-connection"
      value = "Server=legacy-db.company.com;Database=legacy_app;..."
    }
    "legacy-api-token" = {
      name  = "legacy-api-token"
      value = "legacy-system-api-token-value"
    }
  }
}

# Main Key Vault module invocation with legacy access policies
module "legacy_keyvault" {
  source = "../../" # Path to the Key Vault module

  # 1. Location - Auto-maps to region code (WUS)
  location = "West US"

  # 2. Naming convention following BCP standards
  naming = {
    application_code = "LGCY" # Legacy Application
    objective_code   = "KVLT" # Key Vault
    environment      = "C"    # Certification
    correlative      = "01"   # First instance
  }

  # 3. Complete Key Vault configuration with legacy access policies
  keyvault_config = {
    # Required: Azure tenant ID
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Standard SKU for legacy applications
    sku_name = "standard"

    # Legacy-compatible security configuration
    enabled_for_deployment          = true  # Legacy apps may need VM access
    enabled_for_disk_encryption     = true  # Legacy disk encryption
    enabled_for_template_deployment = true  # Legacy ARM templates
    public_network_access_enabled   = true  # Legacy apps may need public access
    purge_protection_enabled        = false # Allow cleanup during migration
    soft_delete_retention_days      = 30    # Shorter retention for testing

    # Permissive network access for legacy compatibility
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Allow" # Legacy apps may not support network restrictions
      ip_rules                   = []
      virtual_network_subnet_ids = []
    }

    # IMPORTANT: Enable legacy access policies mode
    legacy_access_policies_enabled = true

    # Legacy access policies (mutually exclusive with RBAC)
    legacy_access_policies = local.access_policies

    # RBAC assignments must be empty when using legacy access policies
    role_assignments = {}

    # Legacy application secrets
    secrets = local.legacy_secrets

    # Basic keys for legacy application
    keys = {
      "legacy-encryption-key" = {
        name     = "legacy-encryption-key"
        key_type = "RSA"
        key_size = 2048
        key_opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

        tags = {
          Purpose = "Legacy Application Encryption"
          KeyType = "RSA-2048"
        }
      }
    }

    # No resource lock during migration period
    # lock = null (commented out for migration flexibility)

    # Tags indicating migration status
    tags = {
      Environment     = "Certification"
      Application     = local.app_name
      Team            = local.team
      Purpose         = "Legacy Migration"
      AccessModel     = "Legacy Access Policies"
      MigrationStatus = "In Progress"
      MigrationTarget = "RBAC"
      CostCenter      = "LEGACY-MIG-001"
      TemporarySetup  = "true"
      ReviewDate      = "2025-12-31"
    }
  }
}

# Outputs for legacy application integration
output "keyvault_id" {
  description = "The ID of the legacy Key Vault"
  value       = module.legacy_keyvault.key_vault_id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault for legacy application access"
  value       = module.legacy_keyvault.key_vault_uri
}

output "access_policy_summary" {
  description = "Summary of configured access policies"
  value = {
    for policy_name, policy_config in local.access_policies : policy_name => {
      object_id           = policy_config.object_id
      key_permissions     = length(policy_config.key_permissions)
      secret_permissions  = length(policy_config.secret_permissions)
      cert_permissions    = length(policy_config.certificate_permissions)
      storage_permissions = length(policy_config.storage_permissions)
    }
  }
}

output "migration_guidance" {
  description = "Guidance for migrating to RBAC model"
  value = {
    current_model = "Legacy Access Policies"
    target_model  = "Azure RBAC"
    migration_steps = [
      "1. Test applications with RBAC in development environment",
      "2. Update application code to use Azure RBAC roles",
      "3. Create new Key Vault with RBAC enabled",
      "4. Migrate secrets and keys to new Key Vault",
      "5. Update application configurations",
      "6. Decommission legacy Key Vault"
    ]
    recommended_rbac_roles = {
      legacy_app     = "Key Vault Secrets User + Key Vault Crypto User"
      admin_user     = "Key Vault Administrator"
      backup_service = "Key Vault Reader"
      monitoring_app = "Key Vault Reader"
    }
  }
}
