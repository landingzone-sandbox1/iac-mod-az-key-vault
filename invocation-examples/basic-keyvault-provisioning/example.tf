# Repository: https://github.com/landingzone-sandbox/iac-mod-az-key-vault
#
# Use case name: Comprehensive Azure Key Vault Configuration
# Description: Complete example showcasing all features of the Key Vault module including network ACLs, RBAC assignments, management locks, and security configurations.
# When to use: Use this example when you need a production-ready Key Vault with comprehensive security configurations, network restrictions, and role-based access control.
# Considerations:
#   - Requires pre-existing resource group or creates one using the module naming convention
#   - Demonstrates both network_settings and standalone role_assignments parameters
#   - Shows network ACL configuration with IP restrictions and VNet integration
#   - Includes management lock for resource protection
#   - Uses premium SKU for enhanced security features
#   - Configures purge protection and soft delete for data protection
# Variables demonstrated:
#   - All naming convention variables (region_code, application_code, objective_code, environment, correlative)
#   - Network security configurations (public_network_access_enabled, network_settings)
#   - Role assignments with least-privilege principle
#   - Security features (purge_protection_enabled, soft_delete_retention_days)
#   - Service integrations (enabled_for_deployment, enabled_for_disk_encryption, enabled_for_template_deployment)
#   - Resource protection (management lock)
#   - Resource tagging for governance


provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Variables for configuration
variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed"
  default     = "East US 2"
}

variable "environment" {
  type        = string
  description = "Environment code (D=Development, T=Test, P=Production)"
  default     = "P"

  validation {
    condition     = contains(["D", "T", "P"], var.environment)
    error_message = "Environment must be D (Development), T (Test), or P (Production)."
  }
}

variable "allowed_ip_addresses" {
  type        = list(string)
  description = "List of IP addresses allowed to access the Key Vault"
  default     = ["203.0.113.0/24", "198.51.100.0/24"]
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs that can access the Key Vault"
  default     = []
}

# Data sources
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# Random suffix for unique naming
resource "random_integer" "suffix" {
  min = 10
  max = 99
}

# Example Resource Group (in production, this might already exist)
resource "azurerm_resource_group" "example" {
  name     = "RSG-${local.region_code}-${local.application_code}-${var.environment}-${format("%02d", random_integer.suffix.result)}"
  location = var.location

  tags = local.common_tags
}

# Local values for consistent naming and configuration
locals {
  region_code      = "EU2"  # East US 2
  application_code = "DEMO" # Demo application
  objective_code   = "KVLT" # Key Vault
  environment      = var.environment
  correlative      = format("%02d", random_integer.suffix.result)

  common_tags = {
    Environment = var.environment == "D" ? "Development" : var.environment == "T" ? "Test" : "Production"
    Application = "Demo Application"
    Owner       = "Infrastructure Team"
    CostCenter  = "IT-Infrastructure"
    Compliance  = "SOX"
    DataClass   = "Confidential"
    CreatedBy   = "Terraform"
    CreatedDate = timestamp()
    Purpose     = "Key Vault for secrets, keys, and certificates management"
  }

  # Current user/service principal for Key Vault access
  current_principal_id = data.azurerm_client_config.current.object_id
}

# Comprehensive Key Vault module configuration
module "key_vault_comprehensive" {
  source = "../.."

  # Location and basic configuration
  location  = var.location
  tenant_id = data.azurerm_client_config.current.tenant_id

  # Naming convention
  region_code      = local.region_code
  application_code = local.application_code
  objective_code   = local.objective_code
  environment      = local.environment
  correlative      = local.correlative

  # SKU and features
  sku_name                        = "premium" # Premium SKU for enhanced security
  enabled_for_deployment          = true      # Allow VMs to retrieve certificates
  enabled_for_disk_encryption     = true      # Allow Azure Disk Encryption
  enabled_for_template_deployment = true      # Allow ARM template deployments

  # Security settings
  public_network_access_enabled = false # Restrict to specific networks only
  purge_protection_enabled      = true  # Prevent accidental deletion
  soft_delete_retention_days    = 30    # 30 days retention for soft-deleted items

  # Network and RBAC configuration (consolidated approach)
  network_settings = {
    firewall_ips    = var.allowed_ip_addresses
    vnet_subnet_ids = var.subnet_ids
  }

  # Additional standalone role assignments (alternative approach)
  role_assignments = {
    # Reader access for monitoring/auditing
    reader = {
      role_definition_id_or_name = "Key Vault Reader"
      principal_id               = local.current_principal_id
      principal_type             = "ServicePrincipal"
      description                = "Read-only access for monitoring and auditing"
    }
  }

  # Resource protection
  lock = {
    kind = "CanNotDelete"
    name = "prevent-deletion"
  }

  # Comprehensive tagging
  tags = local.common_tags

  # Explicit dependency on resource group
  depends_on = [azurerm_resource_group.example]
}

# Outputs for reference
output "key_vault_name" {
  description = "The name of the created Key Vault"
  value       = module.key_vault_comprehensive.name
}

output "key_vault_id" {
  description = "The ID of the created Key Vault"
  value       = module.key_vault_comprehensive.id
}

output "key_vault_uri" {
  description = "The URI of the created Key Vault"
  value       = module.key_vault_comprehensive.uri
}

output "key_vault_resource_group" {
  description = "The resource group containing the Key Vault"
  value       = azurerm_resource_group.example.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.example.id
}

output "network_configuration" {
  description = "Network access configuration summary"
  value = {
    public_access_enabled = false
    allowed_ips           = var.allowed_ip_addresses
    subnet_access         = length(var.subnet_ids) > 0 ? "Configured" : "Not configured"
  }
}

output "security_features" {
  description = "Security features enabled"
  value = {
    sku                         = "premium"
    purge_protection            = true
    soft_delete_retention       = "30 days"
    disk_encryption_enabled     = true
    template_deployment_enabled = true
    vm_deployment_enabled       = true
    rbac_authorization          = true
  }
}

output "azure_portal_link" {
  description = "Direct link to the Key Vault in Azure Portal"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${module.key_vault_comprehensive.id}"
}
