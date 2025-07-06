# =============================================================================
# Use case name: Enterprise Key Vault with RBAC and Secrets Management
# Description: Example showing how to provision a production-ready Azure Key Vault 
#              with RBAC authorization, secrets management, and enterprise security features.
# 
# When to apply it: 
#   - Production environments requiring secure secret storage
#   - Applications needing centralized credential management
#   - Teams following modern Azure RBAC patterns (not legacy access policies)
#   - Scenarios requiring compliance and audit capabilities
# 
# Considerations:
#   - Requires Azure AD tenant with appropriate permissions
#   - Service principals or managed identities must exist before assignment
#   - Premium SKU recommended for production workloads
#   - Purge protection enabled (cannot be disabled once set)
#   - Network access restricted by default for security
# 
# Variables used:
#   - application_code: "PAYG" - Payment Gateway application identifier
#   - objective_code: "KVLT" - Key Vault resource type identifier  
#   - environment: "P" - Production environment designation
#   - correlative: "01" - First instance of this resource type
#   - tenant_id: Azure AD tenant for authentication
#   - principal_ids: Service principal IDs for RBAC assignments
#   - secrets: Application secrets to be stored securely
# =============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Local variables for this example
locals {
  # Application-specific configuration
  app_name = "payment-gateway"
  team     = "fintech"

  # Service principal IDs (replace with actual values)
  service_principals = {
    app_backend  = "12345678-1234-1234-1234-123456789abc" # Backend service principal
    app_frontend = "87654321-4321-4321-4321-cba987654321" # Frontend service principal
    devops_team  = "11111111-2222-3333-4444-555555555555" # DevOps team principal
  }

  # Secrets to be stored (values should come from secure sources)
  application_secrets = {
    "database-connection-string" = {
      name  = "database-connection-string"
      value = "Server=myserver.database.windows.net;Database=mydatabase;..."
    }
    "api-key-payment-processor" = {
      name  = "api-key-payment-processor"
      value = "pk_live_abc123def456ghi789..."
    }
    "jwt-signing-key" = {
      name  = "jwt-signing-key"
      value = "super-secret-jwt-signing-key-for-tokens"
    }
  }
}

# Main Key Vault module invocation
module "enterprise_keyvault" {
  source = "../../" # Path to the Key Vault module

  # 1. Location - Auto-maps to region code (EUS2)
  location = "East US 2"

  # 2. Naming convention following BCP standards
  naming = {
    application_code = "PAYG" # Payment Gateway
    objective_code   = "KVLT" # Key Vault
    environment      = "P"    # Production
    correlative      = "01"   # First instance
  }

  # 3. Complete Key Vault configuration
  keyvault_config = {
    # Required: Azure tenant ID
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Premium SKU for production with advanced features
    sku_name = "premium"

    # Security configuration for production
    enabled_for_deployment          = false # No VM deployment access
    enabled_for_disk_encryption     = true  # Allow disk encryption
    enabled_for_template_deployment = false # No ARM template access
    public_network_access_enabled   = false # Private access only
    purge_protection_enabled        = true  # Prevent accidental deletion
    soft_delete_retention_days      = 90    # Maximum retention

    # Network security - deny all by default
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      ip_rules                   = [] # Add specific IPs if needed
      virtual_network_subnet_ids = [] # Add subnet IDs if using VNet integration
    }

    # RBAC assignments for least-privilege access
    role_assignments = {
      # Backend service - can read/write secrets
      "backend-secrets-officer" = {
        role_definition_id_or_name = "Key Vault Secrets Officer"
        principal_id               = local.service_principals.app_backend
        principal_type             = "ServicePrincipal"
        description                = "Backend service secret management access"
      }

      # Frontend service - can only read secrets
      "frontend-secrets-user" = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = local.service_principals.app_frontend
        principal_type             = "ServicePrincipal"
        description                = "Frontend service read-only secret access"
      }

      # DevOps team - full administrative access
      "devops-admin" = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = local.service_principals.devops_team
        principal_type             = "ServicePrincipal"
        description                = "DevOps team administrative access"
      }
    }

    # Application secrets
    secrets = local.application_secrets

    # Resource lock to prevent accidental deletion
    lock = {
      kind = "CanNotDelete"
      name = "production-protection-lock"
    }

    # Tags for resource management
    tags = {
      Environment     = "Production"
      Application     = local.app_name
      Team            = local.team
      CostCenter      = "12345"
      DataClass       = "Confidential"
      BackupRequired  = "true"
      MonitoringLevel = "critical"
    }
  }
}

# Outputs for integration with other resources
output "keyvault_id" {
  description = "The ID of the Key Vault"
  value       = module.enterprise_keyvault.key_vault_id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault for application configuration"
  value       = module.enterprise_keyvault.key_vault_uri
}

output "keyvault_name" {
  description = "The name of the Key Vault"
  value       = module.enterprise_keyvault.key_vault_name
}
