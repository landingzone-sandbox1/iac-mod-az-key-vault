variable "location" {
  type        = string
  description = "The Azure location where the resources will be deployed."
  nullable    = false
}

variable "region_code" {
  type        = string
  description = "3 letter Region code (e.g., EU2 for East US 2)"
}

variable "application_code" {
  type        = string
  description = "4 letter abbreviation of the associated application"
}

variable "objective_code" {
  type        = string
  description = "4 letter abbreviation of the objective of the resource"
}

variable "environment" {
  type        = string
  description = "Environment code (e.g., D, P, C, F)"
}

variable "correlative" {
  description = "2-digit correlative number to uniquely identify resources."
  type        = string
}

variable "tenant_id" {
  type        = string
  description = "The Azure tenant ID used for authenticating requests to Key Vault. You can use the `azurerm_client_config` data source to retrieve it."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.tenant_id))
    error_message = "The tenant ID must be a valid GUID. Letters must be lowercase."
  }
}

variable "enabled_for_deployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault."
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = true
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys."
}

variable "enabled_for_template_deployment" {
  type        = bool
  default     = false
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = "The lock level to apply to the Key Vault. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "network_acls" {
  type = object({
    bypass                     = optional(string, "AzureServices")
    default_action             = optional(string, "Deny")
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
The network ACL configuration for the Key Vault.
If not specified then the Key Vault will be created with a firewall that blocks access.
Specify `null` to create the Key Vault with no firewall.

- `bypass` - (Optional) Should Azure Services bypass the ACL. Possible values are `AzureServices` and `None`. Defaults to `AzureServices`.
- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.
- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.
- `virtual_network_subnet_ids` - (Optional) When using with Service Endpoints, a list of subnet IDs to associate with the Key Vault. Defaults to `[]`.
DESCRIPTION

  validation {
    condition     = var.network_acls == null ? true : contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "The bypass value must be either `AzureServices` or `None`."
  }
  validation {
    condition     = var.network_acls == null ? true : contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "The default_action value must be either `Allow` or `Deny`."
  }
}

# Naming convention object (optional - fallback to individual variables if not provided)
variable "naming" {
  description = "Naming convention object for resource naming."
  type = object({
    application_code = string
    region_code      = string
    environment      = string
    correlative      = string
    objective_code   = string
  })
  default = null
}

# Network and RBAC settings (standardized parameter)
variable "network_settings" {
  description = "Network configuration for the Key Vault."
  type = object({
    firewall_ips    = optional(list(string), [])
    vnet_subnet_ids = optional(list(string), [])
  })
  default = {
    firewall_ips    = []
    vnet_subnet_ids = []
  }

  validation {
    condition = alltrue([
      for ip in var.network_settings.firewall_ips : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}(?:/[0-9]{1,2})?$", ip))
    ])
    error_message = "Each firewall IP must be a valid IPv4 address or CIDR block."
  }

  validation {
    condition = alltrue([
      for id in var.network_settings.vnet_subnet_ids : can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", id))
    ])
    error_message = "Each subnet ID must be a valid Azure subnet resource ID."
  }
}

# Standalone role assignments parameter
variable "role_assignments" {
  description = "Role assignments for the Key Vault. Uses least-privilege principle."
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    principal_type                         = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : contains([
        # Key Vault specific least-privilege roles
        "Key Vault Reader",
        "Key Vault Secrets User",
        "Key Vault Secrets Officer",
        "Key Vault Crypto User",
        "Key Vault Crypto Officer",
        "Key Vault Certificate User",
        "Key Vault Certificates Officer",
        # General least-privilege roles
        "Reader",
        "Contributor",
        "Security Reader",
        "Monitoring Reader"
      ], v.role_definition_id_or_name)
    ])
    error_message = "Only least-privilege Key Vault roles are allowed. Use specific Key Vault reader, user, or officer roles."
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : contains(["User", "Group", "ServicePrincipal"], v.principal_type)
    ])
    error_message = "principal_type must be one of: User, Group, ServicePrincipal."
  }

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", v.principal_id))
    ])
    error_message = "principal_id must be a valid GUID format."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Specifies whether public access is permitted."
}

variable "purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled."
}







variable "sku_name" {
  type        = string
  default     = "premium"
  description = "The SKU name of the Key Vault. Default is `premium`. Possible values are `standard` and `premium`."

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The SKU name must be either `standard` or `premium`."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  default     = null
  description = <<DESCRIPTION
The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days.
DESCRIPTION

  validation {
    condition     = var.soft_delete_retention_days == null ? true : var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Value must be between 7 and 90."
  }
  validation {
    condition     = var.soft_delete_retention_days == null ? true : ceil(var.soft_delete_retention_days) == var.soft_delete_retention_days
    error_message = "Value must be an integer."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Map of tags to assign to the Key Vault resource."
}





