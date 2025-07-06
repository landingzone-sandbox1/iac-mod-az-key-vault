# =============================================================================
# LOCAL VALUES FOR NAMING AND COMPUTED PROPERTIES
# =============================================================================

locals {
  # Location to region code mapping (following module-source-local pattern)
  location_to_region_code = {
    # North America
    "East US"          = "EUS"
    "East US 2"        = "EUS2"
    "Central US"       = "CUS"
    "North Central US" = "NCUS"
    "South Central US" = "SCUS"
    "West US"          = "WUS"
    "West US 2"        = "WUS2"
    "West US 3"        = "WUS3"
    "Canada Central"   = "CCAN"
    "Canada East"      = "ECAN"

    # South America
    "Brazil South"     = "BSOU"
    "Brazil Southeast" = "BSE"
    "Mexico Central"   = "MCEN"
    "Chile Central"    = "CCEN"

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
  # RESOURCE GROUP LOGIC
  # =============================================================================

  # Generate BCP-compliant resource group name if not provided  
  # Include objective code to match Key Vault naming pattern
  resource_group_name_generated = "RSG${local.region_code}${local.application_code}${local.objective_code}${local.environment}${local.correlative}"

  # Determine if we need to create a resource group
  create_resource_group = var.keyvault_config.resource_group_name == null ? true : false

  # Final resource group name - either user-provided or auto-generated (from created RG)
  final_rg_name = var.keyvault_config.resource_group_name != null ? var.keyvault_config.resource_group_name : azurerm_resource_group.this[0].name

  # =============================================================================
  # CONFIGURATION LOGIC
  # =============================================================================

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

  # Process RBAC assignments with auto-detection of principal_id and least-privilege validation
  # This uses local.keyvault_rbac_roles to enforce only approved roles are assigned
  processed_role_assignments = {
    for k, v in var.keyvault_config.role_assignments : k => merge(v, {
      principal_id = v.principal_id != null ? v.principal_id : data.azurerm_client_config.current.object_id
    }) if contains(keys(local.keyvault_rbac_roles), v.role_definition_id_or_name) ||             # Check role names
    contains(values(local.keyvault_rbac_roles), v.role_definition_id_or_name) ||                 # Check role UUIDs
    contains(["Key Vault Administrator", "Key Vault Contributor"], v.role_definition_id_or_name) # Allow admin roles
  }

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
  secrets_enabled           = length(var.keyvault_config.secrets) > 0           # Used in: azurerm_key_vault_secret.this
  certificates_enabled      = length(var.keyvault_config.certificates) > 0      # Used in: azurerm_key_vault_certificate.this

  # Key Vault RBAC role definitions (least-privilege only)
  # Used in processed_role_assignments for validation and filtering
  # These roles provide granular access without excessive privileges
  keyvault_rbac_roles = {
    "Key Vault Reader"           = "21090545-7ca7-4776-b22c-e363652d74d2"
    "Key Vault Secrets User"     = "4633458b-17de-408a-b874-0445c86b69e6"
    "Key Vault Crypto User"      = "12338af0-0e69-4776-bea7-57ae8d297424"
    "Key Vault Certificate User" = "db79e9a7-68ee-4b58-9aeb-b90e7c24fcba"
  }
}