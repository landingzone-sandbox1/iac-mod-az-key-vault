# =============================================================================
# DATA SOURCES
# =============================================================================

# Get current Azure client configuration for auto-detection of tenant_id and object_id
data "azurerm_client_config" "current" {}

# =============================================================================
# RESOURCE GROUP CREATION (when not provided)
# =============================================================================

# Create resource group if not specified by user
resource "azurerm_resource_group" "this" {
  count    = local.create_resource_group ? 1 : 0
  name     = local.resource_group_name_generated
  location = var.location

  tags = merge(
    {
      # Default tags for resource group
      Environment    = var.naming.environment == "P" ? "Production" : var.naming.environment == "C" ? "Certification" : var.naming.environment == "F" ? "Functional" : "Development"
      NamingStandard = "BCP-IT-Department"
      ResourceType   = "resource-group"
      Location       = var.location
      CreatedFor     = "Key Vault ${local.keyvault_name}"
    },
    var.keyvault_config.tags
  )
}

# =============================================================================
# AZURE KEY VAULT RESOURCE
# =============================================================================

resource "azurerm_key_vault" "this" {
  location                        = var.location
  name                            = local.keyvault_name
  resource_group_name             = local.final_rg_name
  tenant_id                       = local.final_tenant_id
  sku_name                        = var.keyvault_config.sku_name
  enable_rbac_authorization       = local.rbac_enabled
  enabled_for_deployment          = var.keyvault_config.enabled_for_deployment
  enabled_for_disk_encryption     = var.keyvault_config.enabled_for_disk_encryption
  enabled_for_template_deployment = var.keyvault_config.enabled_for_template_deployment
  public_network_access_enabled   = var.keyvault_config.public_network_access_enabled
  purge_protection_enabled        = var.keyvault_config.purge_protection_enabled
  soft_delete_retention_days      = var.keyvault_config.soft_delete_retention_days
  tags                            = local.merged_tags

  # Always apply network ACLs for security compliance (secure defaults if not specified)
  network_acls {
    bypass                     = local.network_acls_config.bypass
    default_action             = local.network_acls_config.default_action
    ip_rules                   = local.network_acls_config.ip_rules
    virtual_network_subnet_ids = local.network_acls_config.virtual_network_subnet_ids
  }
}

# =============================================================================
# RBAC ASSIGNMENTS 
# =============================================================================

resource "azurerm_role_assignment" "this" {
  for_each = local.processed_role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_key_vault.this.id
  role_definition_name                   = each.value.role_definition_id_or_name
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

# =============================================================================
# KEY VAULT KEYS
# =============================================================================

resource "azurerm_key_vault_key" "this" {
  for_each = local.keys_enabled ? var.keyvault_config.keys : {}

  name         = each.value.name
  key_vault_id = azurerm_key_vault.this.id
  key_type     = each.value.key_type
  key_size     = each.value.key_type == "RSA" || each.value.key_type == "RSA-HSM" ? each.value.key_size : null
  curve        = each.value.key_type == "EC" || each.value.key_type == "EC-HSM" ? each.value.curve : null
  key_opts     = each.value.key_opts

  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags            = each.value.tags

  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy != null ? [each.value.rotation_policy] : []

    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      dynamic "automatic" {
        for_each = rotation_policy.value.automatic != null ? [rotation_policy.value.automatic] : []

        content {
          time_after_creation = automatic.value.time_after_creation
          time_before_expiry  = automatic.value.time_before_expiry
        }
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.this,
    azurerm_key_vault_access_policy.legacy
  ]
}

# =============================================================================
# KEY VAULT SECRETS
# =============================================================================

resource "azurerm_key_vault_secret" "this" {
  for_each = local.secrets_enabled ? var.keyvault_config.secrets : {}

  name            = each.value.name
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = each.value.content_type
  not_before_date = each.value.not_before_date
  expiration_date = each.value.expiration_date
  tags            = each.value.tags

  depends_on = [
    azurerm_role_assignment.this,
    azurerm_key_vault_access_policy.legacy
  ]
}

# =============================================================================
# KEY VAULT CERTIFICATES
# =============================================================================

resource "azurerm_key_vault_certificate" "this" {
  for_each = local.certificates_enabled ? var.keyvault_config.certificates : {}

  name         = each.value.name
  key_vault_id = azurerm_key_vault.this.id
  tags         = each.value.tags

  certificate_policy {
    issuer_parameters {
      name = each.value.certificate_policy.issuer_parameters.name
    }

    key_properties {
      exportable = each.value.certificate_policy.key_properties.exportable
      key_size   = each.value.certificate_policy.key_properties.key_size
      key_type   = each.value.certificate_policy.key_properties.key_type
      reuse_key  = each.value.certificate_policy.key_properties.reuse_key
    }

    dynamic "lifetime_action" {
      for_each = each.value.certificate_policy.lifetime_actions

      content {
        action {
          action_type = lifetime_action.value.action.action_type
        }

        trigger {
          days_before_expiry  = lifetime_action.value.trigger.days_before_expiry
          lifetime_percentage = lifetime_action.value.trigger.lifetime_percentage
        }
      }
    }

    secret_properties {
      content_type = each.value.certificate_policy.secret_properties.content_type
    }

    dynamic "x509_certificate_properties" {
      for_each = each.value.certificate_policy.x509_certificate_properties != null ? [each.value.certificate_policy.x509_certificate_properties] : []

      content {
        extended_key_usage = x509_certificate_properties.value.extended_key_usage
        key_usage          = x509_certificate_properties.value.key_usage
        subject            = x509_certificate_properties.value.subject
        validity_in_months = x509_certificate_properties.value.validity_in_months

        dynamic "subject_alternative_names" {
          for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []

          content {
            dns_names = subject_alternative_names.value.dns_names
            emails    = subject_alternative_names.value.emails
            upns      = subject_alternative_names.value.upns
          }
        }
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.this,
    azurerm_key_vault_access_policy.legacy
  ]
}

# =============================================================================
# PRIVATE ENDPOINTS
# =============================================================================

resource "azurerm_private_endpoint" "this" {
  for_each = local.private_endpoints_enabled ? var.keyvault_config.private_endpoints : {}

  name                = coalesce(each.value.name, "pe-${local.keyvault_name}")
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, local.final_rg_name)
  subnet_id           = each.value.subnet_resource_id
  tags                = each.value.tags

  private_service_connection {
    name                           = coalesce(each.value.private_service_connection_name, "psc-${local.keyvault_name}")
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = each.value.is_manual_connection
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [1] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }
}

# =============================================================================
# MANAGEMENT LOCK
# =============================================================================

resource "azurerm_management_lock" "this" {
  count = local.lock_enabled ? 1 : 0

  lock_level = var.keyvault_config.lock.kind
  name       = coalesce(var.keyvault_config.lock.name, "lock-${local.keyvault_name}")
  scope      = azurerm_key_vault.this.id
  notes      = var.keyvault_config.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

# =============================================================================
# LEGACY ACCESS POLICIES (if enabled)
# =============================================================================

resource "azurerm_key_vault_access_policy" "legacy" {
  for_each = local.legacy_access_policies_enabled ? var.keyvault_config.legacy_access_policies : {}

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.keyvault_config.tenant_id
  object_id    = each.value.object_id

  application_id          = each.value.application_id
  certificate_permissions = each.value.certificate_permissions
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  storage_permissions     = each.value.storage_permissions
}