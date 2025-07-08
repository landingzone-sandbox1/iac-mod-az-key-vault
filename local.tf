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

  # LBS - Key Vault configuration defaults
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = false
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

  # Process RBAC assignments with auto-detection of principal_id and least-privilege validation
  # This uses local.keyvault_rbac_roles to enforce only approved roles are assigned
  processed_role_assignments = {
    for k, v in var.keyvault_config.role_assignments : k => merge(v, {
      principal_id = v.principal_id != null ? v.principal_id : data.azurerm_client_config.current.object_id
    }) if contains(keys(local.keyvault_rbac_roles), v.role_definition_id_or_name) ||           # Check role names
    contains(values(local.keyvault_rbac_roles), v.role_definition_id_or_name) ||               # Check role UUIDs
    contains(["Reader", "Monitoring Reader", "Security Reader"], v.role_definition_id_or_name) # Allow general monitoring roles
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
  private_endpoints_enabled   = length(var.keyvault_config.private_endpoints) > 0   # Used in: azurerm_private_endpoint.this
  keys_enabled                = length(var.keyvault_config.keys) > 0                # Used in: azurerm_key_vault_key.this
  secrets_enabled             = length(var.keyvault_config.secrets) > 0             # Used in: azurerm_key_vault_secret.this
  certificates_enabled        = length(var.keyvault_config.certificates) > 0        # Used in: azurerm_key_vault_certificate.this
  diagnostic_settings_enabled = length(var.keyvault_config.diagnostic_settings) > 0 # Used in: azurerm_monitor_diagnostic_setting.this (LT-4)

  # Key Vault RBAC role definitions (comprehensive least-privilege set)
  # Used in processed_role_assignments for validation and filtering
  # These roles provide granular access following Azure security best practices
  keyvault_rbac_roles = {
    # READ-ONLY ROLES (Least Privilege)
    "Key Vault Reader" = "21090545-7ca7-4776-b22c-e363652d74d2"

    # SECRETS MANAGEMENT (Granular Access)
    "Key Vault Secrets User"    = "4633458b-17de-408a-b874-0445c86b69e6" # Read secrets only
    "Key Vault Secrets Officer" = "b86a8fe4-44ce-4948-aee5-eccb2c155cd7" # Full secret management

    # CRYPTOGRAPHIC OPERATIONS (Granular Access)  
    "Key Vault Crypto User"                    = "12338af0-0e69-4776-bea7-57ae8d297424" # Encrypt/decrypt operations
    "Key Vault Crypto Officer"                 = "14b46e9e-c2b7-41b4-b07b-48a6ebf60603" # Full key management
    "Key Vault Crypto Service Encryption User" = "e147488a-f6f5-4113-8e2d-b22465e65bf6" # Service encryption only
    "Key Vault Crypto Service Release User"    = "08bbd89e-9f13-488c-ac41-acfcb10c90ab" # Key release for VMs

    # CERTIFICATE MANAGEMENT (Granular Access)
    "Key Vault Certificate User"     = "db79e9a7-68ee-4b58-9aeb-b90e7c24fcba" # Read certificates only
    "Key Vault Certificates Officer" = "a4417e6f-fecd-4de8-b567-7b0420556985" # Full certificate management

    # SPECIALIZED OPERATIONS
    "Key Vault Data Access Administrator" = "8b54135c-b56d-4d72-a534-26097cfdc8d8" # Manage role assignments only
  }

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