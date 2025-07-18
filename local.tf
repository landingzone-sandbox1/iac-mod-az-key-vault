# =============================================================================
# LOCAL VALUES FOR NAMING AND COMPUTED PROPERTIES
# =============================================================================

locals {
  # Credicorp region code mapping (3 characters) - supports both lowercase and titlecase
  location_to_region_code = {
    # North America - lowercase variants
    "eastus"         = "EU1"
    "eastus2"        = "EU2"
    "centralus"      = "CU1"
    "northcentralus" = "NCU"
    "southcentralus" = "SCU"
    "westus"         = "WU1"
    "westus2"        = "WU2"
    "westus3"        = "WU3"
    "canadacentral"  = "CC1"
    "canadaeast"     = "CE1"

    # North America - titlecase variants
    "East US"          = "EU1"
    "East US 2"        = "EU2"
    "Central US"       = "CU1"
    "North Central US" = "NCU"
    "South Central US" = "SCU"
    "West US"          = "WU1"
    "West US 2"        = "WU2"
    "West US 3"        = "WU3"
    "Canada Central"   = "CC1"
    "Canada East"      = "CE1"

    # South America - lowercase variants
    "brazilsouth"     = "BS1"
    "brazilsoutheast" = "BSE"
    "mexicocentral"   = "MC1"
    "chilecentral"    = "CL1"

    # South America - titlecase variants
    "Brazil South"     = "BS1"
    "Brazil Southeast" = "BSE"
    "Mexico Central"   = "MC1"
    "Chile Central"    = "CL1"
  }

  # BCP naming convention logic (following module-source-local pattern)
  service_code     = "AZKV" # Fixed service code for Azure Key Vault
  region_code      = local.location_to_region_code[var.location]
  application_code = var.naming.application_code
  objective_code   = var.naming.objective_code
  environment      = var.naming.environment
  correlative      = var.naming.correlative

  # Construct BCP name with objective code - this is the final name (no overrides allowed)
  name = "${local.service_code}${local.region_code}${local.application_code}${local.objective_code}${local.environment}${local.correlative}"

  # Final resource name - always use BCP convention (no user override allowed)
  keyvault_name = local.name

  # =============================================================================
  # CONFIGURATION LOGIC
  # =============================================================================

  # LBS - Key Vault configuration defaults (configurable per environment)
  soft_delete_retention_days    = var.keyvault_config.soft_delete_retention_days != null ? var.keyvault_config.soft_delete_retention_days : 90
  purge_protection_enabled      = var.keyvault_config.purge_protection_enabled != null ? var.keyvault_config.purge_protection_enabled : true
  public_network_access_enabled = var.keyvault_config.public_network_access_enabled != null ? var.keyvault_config.public_network_access_enabled : false
  enabled_for_disk_encryption   = true


  # Tags with BCP naming information
  default_tags = {
    # BCP Standard tags
    Environment   = var.naming.environment == "P" ? "Production" : var.naming.environment == "C" ? "Certification" : var.naming.environment == "F" ? "Functional" : "Development"
    Application   = var.naming.application_code
    ServiceCode   = local.service_code
    RegionCode    = local.region_code
    ObjectiveCode = var.naming.objective_code
    Correlative   = var.naming.correlative

    # Standard operational tags
    ManagedBy      = "terraform"
    Service        = "azure-key-vault"
    NamingStandard = "BCP-IT-Department"
    ResourceType   = "key-vault"
    Location       = var.location
  }

  merged_tags = merge(local.default_tags, var.keyvault_config.tags)

  # Auto-detection logic for optional values
  final_tenant_id = var.keyvault_config.tenant_id != null ? var.keyvault_config.tenant_id : data.azurerm_client_config.current.tenant_id

  # Resource group name handling - create BCP-compliant name when null
  resource_group_name = var.keyvault_config.resource_group_name != null ? var.keyvault_config.resource_group_name.name : "RSG${local.region_code}${local.application_code}${local.objective_code}${local.environment}${local.correlative}"

  # Configuration flags for conditional resource creation
  lock_enabled                   = var.keyvault_config.lock != null
  rbac_enabled                   = !var.keyvault_config.legacy_access_policies_enabled
  legacy_access_policies_enabled = var.keyvault_config.legacy_access_policies_enabled

  # Secure network ACL defaults - always applied for security compliance
  # This ensures the Key Vault always has restrictive network access controls
  network_acls_config = var.keyvault_config.network_acls != null ? var.keyvault_config.network_acls : {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  # Feature flags - used in main.tf for conditional resource creation
  private_endpoints_enabled = length(var.keyvault_config.private_endpoints) > 0 # Used in: azurerm_private_endpoint.this
  keys_enabled              = length(var.keyvault_config.keys) > 0              # Used in: azurerm_key_vault_key.this
  # Count only secrets with actual values (not template-only secrets)
  secrets_enabled = length([
    for k, v in var.keyvault_config.secrets : k
    if v.value != null && v.value != ""
  ]) > 0                                                                     # Used in: azurerm_key_vault_secret.this
  certificates_enabled        = length(var.keyvault_config.certificates) > 0 # Used in: azurerm_key_vault_certificate.this
  diagnostic_settings_enabled = true                                         # Always enabled - diagnostic settings are mandatory (LT-4)

  # =============================================================================
  # MODULE-INTERNAL CONSTANTS
  # =============================================================================

  # Private endpoint constants
  keyvault_subresource_name = "vault"

  # Lock message constants  
  lock_notes_cannot_delete = "Cannot delete the resource or its child resources."
  lock_notes_readonly      = "Cannot delete or modify the resource or its child resources."

  # Computed lock notes based on lock kind
  final_lock_notes = var.keyvault_config.lock != null ? (
    var.keyvault_config.lock.kind == "CanNotDelete" ?
    local.lock_notes_cannot_delete :
    local.lock_notes_readonly
  ) : local.lock_notes_cannot_delete
}