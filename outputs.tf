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
