variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed. Must be one of the approved Credicorp regions."
  nullable    = false

  validation {
    condition = contains(keys({
      # North America regions (approved for Credicorp operations)
      "eastus"         = "EU1"
      "eastus2"        = "EU2" # LBS preferred region
      "centralus"      = "CU1"
      "northcentralus" = "NCU"
      "southcentralus" = "SCU"
      "westus"         = "WU1"
      "westus2"        = "WU2"
      "westus3"        = "WU3"
      "canadacentral"  = "CC1"
      "canadaeast"     = "CE1"

      # South America regions (primary for Latin American operations)
      "brazilsouth"     = "BS1"
      "brazilsoutheast" = "BSE"
      "mexicocentral"   = "MC1"
      "chilecentral"    = "CL1"

      # Titlecase variants (for backwards compatibility)
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
      "Brazil South"     = "BS1"
      "Brazil Southeast" = "BSE"
      "Mexico Central"   = "MC1"
      "Chile Central"    = "CL1"
    }), var.location)

    error_message = <<-EOT
      Invalid Azure location specified. Please use one of the approved Credicorp regions:
      
      North America: eastus, eastus2, centralus, northcentralus, southcentralus, westus, westus2, westus3, canadacentral, canadaeast
      South America: brazilsouth, brazilsoutheast, mexicocentral, chilecentral
      
      Note: East US 2 (eastus2) is the preferred region for Key Vault deployments as per LBS requirements.
      Ensure the selected region aligns with your application's compliance and data residency requirements.
      
      These locations correspond to the region codes defined in the Credicorp naming convention.
    EOT
  }
}

# Naming convention object (excludes region_code - auto-generated from location)
variable "naming" {
  description = "Naming convention object for resource naming following BCP standards."
  type = object({
    application_code = string # 4 letter abbreviation of the associated application
    objective_code   = string # 4 letter abbreviation of the objective of the resource
    environment      = string # Environment code (e.g., D, P, C, F)
    correlative      = string # 2-digit correlative number to uniquely identify resources
  })

  validation {
    condition     = can(regex("^[A-Z0-9]{4}$", var.naming.application_code))
    error_message = "application_code must be exactly 4 uppercase alphanumeric characters."
  }

  validation {
    condition     = contains(["D", "P", "C", "F"], var.naming.environment)
    error_message = "environment must be one of: D (Development), P (Production), C (Certification), F (Functional Test)."
  }

  validation {
    condition     = can(regex("^[0-9]{2}$", var.naming.correlative))
    error_message = "correlative must be exactly 2 digits (e.g., '01', '02')."
  }

  validation {
    condition     = can(regex("^[A-Z0-9]{3,4}$", var.naming.objective_code))
    error_message = "objective_code must be 3-4 uppercase alphanumeric characters."
  }
}

# Complete Key Vault configuration consolidated into keyvault_config object
variable "keyvault_config" {
  description = "Key Vault configuration. Must include resource_group_name (existing), name, sku_name, and diagnostic_settings."
  type = object({
    # Required
    tenant_id = string # Azure tenant ID for authentication

    # Basic Configuration (with defaults)
    enabled_for_deployment          = optional(bool, false)       # VM certificate access 
    enabled_for_template_deployment = optional(bool, false)       # ARM template access
    sku_name                        = optional(string, "premium") # standard, premium

    # Security and Network Configuration (environment-specific)
    purge_protection_enabled      = optional(bool)       # Enable/disable purge protection (null = auto based on environment)
    public_network_access_enabled = optional(bool)       # Enable/disable public network access (null = default false)
    soft_delete_retention_days    = optional(number, 90) # Soft delete retention period

    # Resource Management
    resource_group_name = optional(object({
      create_new = bool
      name       = optional(string, null)
    }))
    lock = optional(object({
      kind = string # CanNotDelete, ReadOnly
      name = optional(string, null)
    }))

    # Network Access Control
    network_acls = optional(object({
      bypass                     = optional(string, "AzureServices") # AzureServices, None
      default_action             = optional(string, "Deny")          # Allow, Deny
      ip_rules                   = optional(list(string), [])        # CIDR blocks
      virtual_network_subnet_ids = optional(list(string), [])        # Subnet IDs
    }))

    # Legacy Access Policies (for backwards compatibility)
    legacy_access_policies_enabled = optional(bool, false)
    legacy_access_policies = optional(map(object({
      object_id               = string
      application_id          = optional(string)
      certificate_permissions = optional(list(string))
      key_permissions         = optional(list(string))
      secret_permissions      = optional(list(string))
      storage_permissions     = optional(list(string))
    })), {})

    # Private Endpoints
    private_endpoints = optional(map(object({
      subnet_resource_id              = string
      private_dns_zone_resource_ids   = optional(list(string), [])
      private_dns_zone_group_name     = optional(string, "default")
      private_service_connection_name = optional(string)
      name                            = optional(string)
      location                        = optional(string)
      resource_group_name             = optional(string)
      is_manual_connection            = optional(bool, false)
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
      tags = optional(map(string), {})
    })), {})

    # Key Vault Keys
    keys = optional(map(object({
      name     = string
      key_type = string                 # RSA, EC, RSA-HSM, EC-HSM
      key_size = optional(number, 2048) # For RSA keys: 2048, 3072, 4096
      curve    = optional(string)       # For EC keys: P-256, P-384, P-521, P-256K
      key_opts = list(string)           # decrypt, encrypt, sign, unwrapKey, verify, wrapKey

      rotation_policy = optional(object({
        automatic = optional(object({
          time_after_creation = optional(string) # ISO 8601 duration
          time_before_expiry  = optional(string) # ISO 8601 duration
        }))
        expire_after         = optional(string) # ISO 8601 duration
        notify_before_expiry = optional(string) # ISO 8601 duration
      }))

      not_before_date = optional(string) # RFC 3339 date
      expiration_date = optional(string) # RFC 3339 date
      tags            = optional(map(string), {})
    })), {})

    # Key Vault Secrets
    secrets = optional(map(object({
      name            = string
      value           = optional(string) # Optional - enables template secrets without values
      content_type    = optional(string) # MIME type
      not_before_date = optional(string) # RFC 3339 date
      expiration_date = optional(string) # RFC 3339 date
      tags            = optional(map(string), {})
    })), {})

    # Key Vault Certificates
    certificates = optional(map(object({
      name = string

      # Certificate Policy
      certificate_policy = object({
        issuer_parameters = object({
          name = string # Self, Unknown, or certificate authority name
        })

        key_properties = object({
          exportable = bool
          key_size   = number
          key_type   = string # RSA, EC
          reuse_key  = bool
        })

        lifetime_actions = optional(list(object({
          action = object({
            action_type = string # AutoRenew, EmailContacts
          })
          trigger = object({
            days_before_expiry  = optional(number)
            lifetime_percentage = optional(number)
          })
        })), [])

        secret_properties = object({
          content_type = string # application/x-pkcs12, application/x-pem-file
        })

        x509_certificate_properties = optional(object({
          extended_key_usage = optional(list(string), [])
          key_usage          = list(string)
          subject            = string
          validity_in_months = number

          subject_alternative_names = optional(object({
            dns_names = optional(list(string), [])
            emails    = optional(list(string), [])
            upns      = optional(list(string), [])
          }))
        }))
      })

      # Certificate attributes
      not_before_date = optional(string)
      expiration_date = optional(string)
      tags            = optional(map(string), {})
    })), {})

    # Resource Tags
    tags = optional(map(string), {})

    # LT-4: Diagnostic Settings for Security Investigation (NUEVO LBS)
    diagnostic_settings = optional(map(object({
      name                           = string
      log_analytics_workspace_id     = optional(string)
      storage_account_id             = optional(string)
      eventhub_authorization_rule_id = optional(string)
      eventhub_name                  = optional(string)
      partner_solution_id            = optional(string)

      # LBS requirement: AuditEvent logs for security investigation
      enabled_logs = optional(list(object({
        category       = optional(string)
        category_group = optional(string)
        })), [
        {
          category_group = "audit" # Required by LBS for AuditEvent logs
        }
      ])

      # Performance and security metrics
      metrics = optional(list(object({
        category = string
        enabled  = optional(bool, true)
        })), [
        {
          category = "AllMetrics"
          enabled  = true
        }
      ])
    })), {})
  })

  # Tenant ID validation
  validation {
    condition     = var.keyvault_config.tenant_id == null || can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.keyvault_config.tenant_id))
    error_message = "The tenant ID must be a valid GUID with lowercase letters, or null to auto-detect."
  }

  # Lock validation
  validation {
    condition     = var.keyvault_config.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.keyvault_config.lock.kind) : true
    error_message = "Lock kind must be either 'CanNotDelete' or 'ReadOnly'."
  }

  # SKU validation
  validation {
    condition = (
      (var.naming.environment == "P" && var.keyvault_config.sku_name == "premium") ||
      (contains(["C", "D", "F"], var.naming.environment) && var.keyvault_config.sku_name == "standard")
    )
    error_message = "The SKU name must be 'premium' for Production (P) environment, and 'standard' for Certification (C), Development (D), or Infrastructure (F) environments."
  }

  # Key validation
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.keys : contains(["RSA", "EC", "RSA-HSM", "EC-HSM"], v.key_type)
    ])
    error_message = "Key type must be one of: RSA, EC, RSA-HSM, EC-HSM."
  }

  # Legacy Access Policy validation for P, D, C environments
  validation {
    condition = (
      !var.keyvault_config.legacy_access_policies_enabled ||
      !contains(["P", "D", "C"], var.naming.environment) ||
      alltrue([
        for ap in values(var.keyvault_config.legacy_access_policies) : (
          # Key management operations
          alltrue([
            contains([for p in ap.key_permissions : lower(p)], "get"),
            contains([for p in ap.key_permissions : lower(p)], "list"),
            contains([for p in ap.key_permissions : lower(p)], "create"),
            contains([for p in ap.key_permissions : lower(p)], "recover"),
            contains([for p in ap.key_permissions : lower(p)], "delete"),
            contains([for p in ap.key_permissions : lower(p)], "restore"),
            contains([for p in ap.key_permissions : lower(p)], "purge"),
            # Cryptographic operations (all)
            contains([for p in ap.key_permissions : lower(p)], "decrypt"),
            contains([for p in ap.key_permissions : lower(p)], "encrypt"),
            contains([for p in ap.key_permissions : lower(p)], "unwrapkey"),
            contains([for p in ap.key_permissions : lower(p)], "wrapkey"),
            contains([for p in ap.key_permissions : lower(p)], "verify"),
            contains([for p in ap.key_permissions : lower(p)], "sign"),
            # Rotation policy
            contains([for p in ap.key_permissions : lower(p)], "getrotationpolicy")
          ])
        )
      ])
    )
    error_message = <<-EOT
      For environments P, D, or C, all legacy access policies must include:
      - Key management: get, list, create, recover, delete, restore, purge
      - Cryptographic: decrypt, encrypt, unwrapKey, wrapKey, verify, sign
      - Rotation policy: getrotationpolicy
    EOT
  }
  # Legacy Access Policy validation for Infrastructure environment F
  validation {
    condition = (
      !var.keyvault_config.legacy_access_policies_enabled ||
      var.naming.environment != "F" ||
      alltrue([
        for ap in values(var.keyvault_config.legacy_access_policies) : (
          contains([for p in ap.secret_permissions : lower(p)], "get")
        )
      ])
    )
    error_message = "For Infrastructure environment F, all legacy access policies must include 'get' in secret_permissions."
  }

  # Secret name validation - ensure consistent naming
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.secrets : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$", v.name))
    ])
    error_message = "Secret names must start and end with alphanumeric characters, and can contain hyphens in the middle. Single character names are allowed."
  }

  # Secret value validation - when provided, must not be empty
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.secrets : (
        v.value == null || length(v.value) >= 1
      )
    ])
    error_message = "Secret values must be either null (template-only) or contain at least 1 character. Empty strings are not allowed."
  }
}
