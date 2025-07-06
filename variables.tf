variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed."
  nullable    = false
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
  description = "Azure Key Vault service configuration following module-template pattern"
  type = object({
    # Required
    tenant_id = string # Azure tenant ID for authentication

    # Basic Configuration (with defaults)
    enabled_for_deployment          = optional(bool, false)       # VM certificate access
    enabled_for_disk_encryption     = optional(bool, true)        # Disk encryption access  
    enabled_for_template_deployment = optional(bool, false)       # ARM template access
    public_network_access_enabled   = optional(bool, false)       # Public access
    purge_protection_enabled        = optional(bool, true)        # Purge protection
    sku_name                        = optional(string, "premium") # standard, premium
    soft_delete_retention_days      = optional(number, 90)        # 7-90 days

    # Resource Management
    resource_group_name = optional(string, null) # Target resource group - null to auto-create
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

    # RBAC Assignments
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      principal_type                         = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})

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
      value           = string
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
    condition     = contains(["standard", "premium"], var.keyvault_config.sku_name)
    error_message = "The SKU name must be either 'standard' or 'premium'."
  }

  # Soft delete retention validation
  validation {
    condition     = var.keyvault_config.soft_delete_retention_days >= 7 && var.keyvault_config.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }

  # Key validation
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.keys : contains(["RSA", "EC", "RSA-HSM", "EC-HSM"], v.key_type)
    ])
    error_message = "Key type must be one of: RSA, EC, RSA-HSM, EC-HSM."
  }

  # Role assignments validation - least-privilege enforcement
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.role_assignments : contains(["User", "Group", "ServicePrincipal"], v.principal_type)
    ])
    error_message = "principal_type must be one of: User, Group, ServicePrincipal."
  }

  # Least-privilege role validation
  validation {
    condition = alltrue([
      for k, v in var.keyvault_config.role_assignments : contains([
        # Least-privilege roles (recommended)
        "Key Vault Reader", "Key Vault Secrets User", "Key Vault Crypto User", "Key Vault Certificate User",
        # Role UUIDs (alternative format)
        "21090545-7ca7-4776-b22c-e363652d74d2", "4633458b-17de-408a-b874-0445c86b69e6",
        "12338af0-0e69-4776-bea7-57ae8d297424", "db79e9a7-68ee-4b58-9aeb-b90e7c24fcba",
        # Administrative roles (use sparingly)
        "Key Vault Administrator", "Key Vault Contributor"
      ], v.role_definition_id_or_name)
    ])
    error_message = "Only approved least-privilege roles are allowed. Use: Key Vault Reader, Key Vault Secrets User, Key Vault Crypto User, Key Vault Certificate User, or administrative roles sparingly."
  }
}