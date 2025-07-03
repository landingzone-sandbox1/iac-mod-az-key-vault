resource "azurerm_key_vault" "this" {
  location                        = var.location
  name                            = "${local.service_code_akv}${local.region_code}${local.application_code}${local.objective_code}${local.environment}${local.correlative}"
  resource_group_name             = local.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  enable_rbac_authorization       = true
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  public_network_access_enabled   = var.public_network_access_enabled
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days != null ? var.soft_delete_retention_days : 90
  tags                            = var.tags

  dynamic "network_acls" {
    # Prioritize network_settings, then fall back to network_acls
    for_each = length(var.network_settings.firewall_ips) > 0 || length(var.network_settings.vnet_subnet_ids) > 0 ? {
      this = {
        bypass                     = "AzureServices"
        default_action             = "Deny"
        ip_rules                   = var.network_settings.firewall_ips
        virtual_network_subnet_ids = var.network_settings.vnet_subnet_ids
      }
    } : (var.network_acls != null ? { this = var.network_acls } : {})

    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }
}

# Role assignments for the Key Vault (standalone parameter)
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_key_vault.this.id
  role_definition_name                   = each.value.role_definition_id_or_name
  description                            = each.value.description
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${azurerm_key_vault.this.name}")
  scope      = azurerm_key_vault.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}