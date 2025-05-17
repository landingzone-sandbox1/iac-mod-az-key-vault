# Repository: https://github.com/landingzone-sandbox/iac-deploy-tf-az-example-key-vault
#
# Use case name: Basic Azure Key Vault Provisioning
# Description: Example of how to provision a basic Azure Key Vault using the module with recovery settings enabled.
# When to use: Use when a basic Key Vault is required to store secrets, keys, or certificates in a secure and centralized manner.
# Considerations:
#   - Requires that the resource group is created beforehand.
#   - The provider "azurerm" must be configured with soft delete recovery features enabled.
#   - Assumes access to the current Azure tenant ID and object ID through azurerm_client_config.
#   - The module generates the Key Vault name internally based on input variables.
# Variables sent:
#   - location: Azure region where the Key Vault will be deployed.
#   - resource_group_name: Name of the pre-existing resource group.
#   - tenant_id: Azure tenant ID where the Key Vault will be associated.
#   - region_code: Short region code to ensure unique naming.
#   - application_code: Application or project code.
#   - objective_code: Logical purpose or function of the resource.
#   - environment: Environment identifier (e.g., dev, test, prod).
#   - correlative: Numeric or string value for uniqueness (e.g., "001").
#   - object_id: Principal object ID with access permissions.
#   - tags: Key-value map of standard resource tags.
# Variables not sent:
#   - name: The Key Vault name is derived within the module using the input variables.

module "azure_key_vault_example" {
  source              = "git::ssh://git@github.com/landingzone-sandbox/iac-mod-az-key-vault.git"
  location            = var.location
  resource_group_name = module.azure_rg_example_for_akv.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  region_code         = var.region_code
  application_code    = var.application_code
  objective_code      = var.objective_code
  environment         = var.environment
  correlative         = var.correlative
  object_id           = data.azurerm_client_config.current.object_id
  tags                = var.tags
}
