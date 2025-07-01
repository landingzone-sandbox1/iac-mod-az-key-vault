<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.28.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.28.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/4.28.0/docs/resources/key_vault) | resource |
| [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/4.28.0/docs/resources/management_lock) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_code"></a> [application\_code](#input\_application\_code) | 4 letter abbreviation of the associated application | `string` | n/a | yes |
| <a name="input_correlative"></a> [correlative](#input\_correlative) | 2-digit correlative number to uniquely identify resources. | `string` | n/a | yes |
| <a name="input_enabled_for_deployment"></a> [enabled\_for\_deployment](#input\_enabled\_for\_deployment) | Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault. | `bool` | `false` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. | `bool` | `true` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code (e.g., D, P, C, F) | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The Azure location where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_lock"></a> [lock](#input\_lock) | The lock level to apply to the Key Vault. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`. | <pre>object({<br/>    kind = string<br/>    name = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | The network ACL configuration for the Key Vault.<br/>If not specified then the Key Vault will be created with a firewall that blocks access.<br/>Specify `null` to create the Key Vault with no firewall.<br/><br/>- `bypass` - (Optional) Should Azure Services bypass the ACL. Possible values are `AzureServices` and `None`. Defaults to `AzureServices`.<br/>- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.<br/>- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.<br/>- `virtual_network_subnet_ids` - (Optional) When using with Service Endpoints, a list of subnet IDs to associate with the Key Vault. Defaults to `[]`. | <pre>object({<br/>    bypass                     = optional(string, "AzureServices")<br/>    default_action             = optional(string, "Deny")<br/>    ip_rules                   = optional(list(string), [])<br/>    virtual_network_subnet_ids = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_objective_code"></a> [objective\_code](#input\_objective\_code) | 4 letter abbreviation of the objective of the resource | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Specifies whether public access is permitted. | `bool` | `false` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled. | `bool` | `true` | no |
| <a name="input_region_code"></a> [region\_code](#input\_region\_code) | 3 letter Region code (e.g., EU2 for East US 2) | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name of the Key Vault. Default is `premium`. Possible values are `standard` and `premium`. | `string` | `"premium"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to the Key Vault resource. | `map(string)` | `null` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | The Azure tenant ID used for authenticating requests to Key Vault. You can use the `azurerm_client_config` data source to retrieve it. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the AKV |
| <a name="output_name"></a> [name](#output\_name) | The name of the AKV |
| <a name="output_resource"></a> [resource](#output\_resource) | The complete Azure Key Vault resource object |
| <a name="output_uri"></a> [uri](#output\_uri) | The URI of the AKV |
<!-- END_TF_DOCS -->