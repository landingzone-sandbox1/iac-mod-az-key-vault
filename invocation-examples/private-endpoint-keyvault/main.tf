# =============================================================================
# Use case name: Secure Key Vault with Private Endpoint Connectivity
# Description: Example showing how to provision an Azure Key Vault with private
#              endpoint connectivity for secure network access in enterprise environments.
# 
# When to apply it:
#   - Production environments with strict network security requirements
#   - Hub-and-spoke network architectures
#   - Zero-trust network security models
#   - Compliance requirements mandating private connectivity
#   - Applications running in private subnets without internet access
# 
# Considerations:
#   - Requires existing virtual network and subnet with private endpoint support
#   - Private DNS zone must be configured for name resolution
#   - Network security groups must allow private endpoint traffic
#   - Applications must be deployed in the same or peered virtual networks
#   - Public network access is disabled for maximum security
# 
# Variables used:
#   - application_code: "BANK" - Banking application identifier
#   - objective_code: "KVLT" - Key Vault resource type identifier
#   - environment: "P" - Production environment designation
#   - correlative: "01" - First instance of this resource type
#   - subnet_id: Subnet where private endpoint will be deployed
#   - private_dns_zone_id: Private DNS zone for Key Vault name resolution
#   - vnet_resource_group: Resource group containing networking resources
# =============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Data sources for existing networking resources (replace with actual values)
data "azurerm_subnet" "private_endpoints" {
  name                 = "subnet-private-endpoints" # Replace with actual subnet name
  virtual_network_name = "vnet-hub-prod"            # Replace with actual VNet name
  resource_group_name  = "rg-networking-prod"       # Replace with actual RG name
}

data "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-networking-prod" # Replace with actual RG name
}

# Local variables for this example
locals {
  # Application-specific configuration
  app_name = "banking-platform"
  team     = "banking-security"

  # Network configuration
  network_config = {
    subnet_id              = data.azurerm_subnet.private_endpoints.id
    private_dns_zone_ids   = [data.azurerm_private_dns_zone.keyvault.id]
    private_dns_zone_group = "default"
    resource_group_name    = data.azurerm_subnet.private_endpoints.resource_group_name
  }

  # Banking application secrets (highly sensitive)
  banking_secrets = {
    "core-banking-api-key" = {
      name            = "core-banking-api-key"
      value           = "super-secret-core-banking-api-key" # Should come from secure source
      content_type    = "application/json"
      expiration_date = "2025-12-31T23:59:59Z"
    }
    "encryption-master-key" = {
      name            = "encryption-master-key"
      value           = "master-encryption-key-for-pii-data" # Should come from secure source
      content_type    = "text/plain"
      expiration_date = "2025-12-31T23:59:59Z"
    }
  }

  # Service principal for banking application (replace with actual)
  banking_app_principal_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
}

# Main Key Vault module invocation with private endpoint
module "secure_keyvault" {
  source = "../../" # Path to the Key Vault module

  # 1. Location - Auto-maps to region code (EUS)
  location = "East US"

  # 2. Naming convention following BCP standards
  naming = {
    application_code = "BANK" # Banking Platform
    objective_code   = "KVLT" # Key Vault
    environment      = "P"    # Production
    correlative      = "01"   # First instance
  }

  # 3. Complete Key Vault configuration with private endpoint
  keyvault_config = {
    # Required: Azure tenant ID
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Premium SKU for production with HSM support
    sku_name = "premium"

    # Maximum security configuration
    enabled_for_deployment          = false # No VM deployment access
    enabled_for_disk_encryption     = true  # Allow disk encryption only
    enabled_for_template_deployment = false # No ARM template access
    public_network_access_enabled   = false # Private access only via endpoint
    purge_protection_enabled        = true  # Maximum protection
    soft_delete_retention_days      = 90    # Maximum retention

    # Strict network security - deny all public access
    network_acls = {
      bypass                     = "None" # No bypass for maximum security
      default_action             = "Deny" # Deny all access
      ip_rules                   = []     # No IP allowlist
      virtual_network_subnet_ids = []     # No VNet rules (using private endpoint)
    }

    # Private endpoint configuration for secure connectivity
    private_endpoints = {
      "banking-pe" = {
        subnet_resource_id              = local.network_config.subnet_id
        private_dns_zone_resource_ids   = local.network_config.private_dns_zone_ids
        private_dns_zone_group_name     = local.network_config.private_dns_zone_group
        name                            = "pe-banking-keyvault"
        resource_group_name             = local.network_config.resource_group_name
        private_service_connection_name = "psc-banking-keyvault"
        is_manual_connection            = false

        # Optional: Custom IP configuration
        ip_configurations = {}

        tags = {
          Purpose         = "Secure Banking Access"
          NetworkSecurity = "Private"
        }
      }
    }

    # Minimal RBAC assignments for banking application
    role_assignments = {
      # Banking application - secrets access only
      "banking-app-secrets" = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = local.banking_app_principal_id
        principal_type             = "ServicePrincipal"
        description                = "Banking application secret access"
      }

      # Security team - read-only monitoring access
      "security-monitoring" = {
        role_definition_id_or_name = "Key Vault Reader"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Security team monitoring access"
      }
    }

    # High-security cryptographic keys for banking
    keys = {
      "customer-data-encryption" = {
        name     = "customer-data-encryption"
        key_type = "RSA-HSM" # Hardware Security Module
        key_size = 4096      # Maximum key size
        key_opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"]

        # Strict rotation policy
        rotation_policy = {
          expire_after         = "P180D" # 6 months
          notify_before_expiry = "P14D"  # 14 days notice
          automatic = {
            time_before_expiry = "P7D" # Auto-rotate 7 days before expiry
          }
        }

        tags = {
          DataClass     = "Highly Confidential"
          ComplianceReq = "PCI-DSS, SOX"
          KeyType       = "Customer Data Encryption"
        }
      }
    }

    # Banking application secrets
    secrets = local.banking_secrets

    # Maximum protection lock
    lock = {
      kind = "CanNotDelete"
      name = "banking-security-lock"
    }

    # Comprehensive tags for compliance and governance
    tags = {
      Environment         = "Production"
      Application         = local.app_name
      Team                = local.team
      DataClassification  = "Highly Confidential"
      ComplianceScope     = "PCI-DSS, SOX, Basel-III"
      CostCenter          = "BANK-SEC-001"
      BusinessCriticality = "Mission Critical"
      NetworkAccess       = "Private Only"
      BackupRequired      = "true"
      MonitoringLevel     = "maximum"
      AuditRequired       = "true"
    }
  }
}

# Outputs for banking application integration
output "keyvault_id" {
  description = "The ID of the secure Key Vault"
  value       = module.secure_keyvault.key_vault_id
}

output "keyvault_uri" {
  description = "The private URI of the Key Vault (accessible via private endpoint only)"
  value       = module.secure_keyvault.key_vault_uri
}

output "private_endpoint_ip" {
  description = "Private IP address of the Key Vault endpoint"
  value       = module.secure_keyvault.private_endpoint_private_ip_address
  sensitive   = false
}

output "dns_configuration" {
  description = "DNS configuration for private endpoint access"
  value = {
    private_dns_zone = data.azurerm_private_dns_zone.keyvault.name
    fqdn             = "${module.secure_keyvault.key_vault_name}.vault.azure.net"
  }
}

output "security_features" {
  description = "Security features enabled for this Key Vault"
  value = {
    private_access_only = true
    hsm_keys_enabled    = true
    purge_protection    = true
    network_isolation   = "Complete"
    rbac_enabled        = true
  }
}
