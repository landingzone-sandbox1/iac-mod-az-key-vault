output "id" {
  description = "The ID of the AKV"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "The name of the AKV"
  value       = azurerm_key_vault.this.name
}
