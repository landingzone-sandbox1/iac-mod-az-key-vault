output "resource" {
  description = "The complete Azure Key Vault resource object"
  value = {
    id                              = azurerm_key_vault.this.id
    name                            = azurerm_key_vault.this.name
    uri                             = azurerm_key_vault.this.vault_uri
    location                        = azurerm_key_vault.this.location
    resource_group_name             = azurerm_key_vault.this.resource_group_name
    tenant_id                       = azurerm_key_vault.this.tenant_id
    sku_name                        = azurerm_key_vault.this.sku_name
    enable_rbac_authorization       = azurerm_key_vault.this.enable_rbac_authorization
    enabled_for_deployment          = azurerm_key_vault.this.enabled_for_deployment
    enabled_for_disk_encryption     = azurerm_key_vault.this.enabled_for_disk_encryption
    enabled_for_template_deployment = azurerm_key_vault.this.enabled_for_template_deployment
    public_network_access_enabled   = azurerm_key_vault.this.public_network_access_enabled
    purge_protection_enabled        = azurerm_key_vault.this.purge_protection_enabled
    soft_delete_retention_days      = azurerm_key_vault.this.soft_delete_retention_days
  }
}

# Legacy outputs for backward compatibility
output "id" {
  description = "The ID of the AKV"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "The name of the AKV"
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "The URI of the AKV"
  value       = azurerm_key_vault.this.vault_uri
}

# New outputs for LBS compliance verification
output "diagnostic_settings" {
  description = "Diagnostic settings configuration for LT-4 compliance"
  value = {
    enabled = local.diagnostic_settings_enabled
    settings = local.diagnostic_settings_enabled ? {
      for k, v in azurerm_monitor_diagnostic_setting.this : k => {
        name                       = v.name
        log_analytics_workspace_id = v.log_analytics_workspace_id
        audit_logs_enabled         = true # Always enabled in LBS configuration
      }
    } : {}
  }
}

output "security_compliance_status" {
  description = "Security compliance status for MVP3.2 LZC-Platform controls"
  value = {
    # NS-2: Secure cloud services with network controls
    ns_2_private_link_enabled   = local.private_endpoints_enabled
    ns_2_public_access_disabled = !azurerm_key_vault.this.public_network_access_enabled
    ns_2_network_controls       = true # Always applied via network_acls

    # IM-7: Restrict resource access based on conditions  
    im_7_conditional_access     = local.network_acls_config.default_action == "Deny"
    im_7_selected_networks_only = length(local.network_acls_config.ip_rules) > 0 || length(local.network_acls_config.virtual_network_subnet_ids) > 0

    # PA-7: Follow just enough administration principle
    pa_7_rbac_enabled    = azurerm_key_vault.this.enable_rbac_authorization
    pa_7_least_privilege = false # RBAC assignments managed outside module

    # DP-7: Use a secure certificate management process
    dp_7_key_management         = local.keys_enabled
    dp_7_certificate_management = local.certificates_enabled

    # LT-1: Enable threat detection capabilities (implemented in examples)
    lt_1_defender_ready = true # Module ready for Defender enablement

    # LT-4: Enable logging for security investigation  
    lt_4_diagnostic_settings = local.diagnostic_settings_enabled
    lt_4_audit_logging       = local.diagnostic_settings_enabled
  }
}
