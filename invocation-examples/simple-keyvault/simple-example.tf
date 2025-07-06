# =============================================================================
# SIMPLE AZURE KEY VAULT EXAMPLE
# =============================================================================
# Repository: https://github.com/landingzone-sandbox/iac-mod-az-key-vault
# Use case: Minimal Key Vault for development and testing
# Description: Shows the simplest possible configuration using the module-template pattern
# When to use: Development environments, proof-of-concepts, or learning the module
# Note: This file uses the shared provider configuration from example.tf

# Simple Key Vault configuration
module "simple_key_vault" {
  source = "../.."

  # Required: Location (auto-maps to region code)
  location = var.location

  # Required: Naming convention
  naming = {
    application_code = "DEMO" # Your application code (4 chars)
    environment      = var.environment
    correlative      = "01"
    objective_code   = "KVLT" # Key Vault purpose code
  }

  # All Key Vault configuration
  keyvault_config = {
    # Required: Tenant ID for authentication
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Optional: Use existing resource group from main example
    resource_group_name = azurerm_resource_group.example.name

    # Optional: Basic configuration (these are the defaults if not specified)
    sku_name                      = "standard" # Use standard for development
    public_network_access_enabled = true       # Allow public access for development
    purge_protection_enabled      = false      # Disable for easier cleanup in dev
    soft_delete_retention_days    = 7          # Minimum retention for dev

    # Grant current user access for management
    rbac_assignments = {
      "current_user" = {
        role_definition_id_or_name = "Key Vault Secrets Officer"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Full access for Key Vault management"
      }
    }

    # Basic tagging
    tags = {
      Environment = "Development"
      Purpose     = "Simple Testing"
      Owner       = "Development Team"
      Example     = "simple-key-vault"
    }
  }
}

# Simple example outputs (prefixed to avoid conflicts)
output "simple_key_vault_name" {
  description = "Name of the simple Key Vault"
  value       = module.simple_key_vault.name
}

output "simple_key_vault_uri" {
  description = "URI of the simple Key Vault"
  value       = module.simple_key_vault.uri
}

output "simple_instructions" {
  description = "Next steps for using your simple Key Vault"
  value = {
    add_secret   = "az keyvault secret set --vault-name ${module.simple_key_vault.name} --name 'my-secret' --value 'my-secret-value'"
    list_secrets = "az keyvault secret list --vault-name ${module.simple_key_vault.name}"
    portal_link  = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${module.simple_key_vault.id}"
    naming_used  = "Service: AZKV, Region: ${local.region_code_examples}, App: DEMO, Objective: KVLT, Env: ${var.environment}, Correlative: ${format("%02d", random_integer.suffix.result + 3)}"
  }
}
