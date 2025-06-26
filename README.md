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
| <a name="input_certificate_permissions"></a> [certificate\_permissions](#input\_certificate\_permissions) | List of permissions for certificates in the Key Vault. | `list(string)` | <pre>[<br/>  "Get",<br/>  "List",<br/>  "Create",<br/>  "Delete"<br/>]</pre> | no |
| <a name="input_correlative"></a> [correlative](#input\_correlative) | n/a | `string` | `"01"` | no |
| <a name="input_enabled_for_deployment"></a> [enabled\_for\_deployment](#input\_enabled\_for\_deployment) | Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the vault. | `bool` | `false` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. | `bool` | `true` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code (e.g., D, P, C, F) | `string` | n/a | yes |
| <a name="input_key_permissions"></a> [key\_permissions](#input\_key\_permissions) | List of permissions for keys in the Key Vault. | `list(string)` | <pre>[<br/>  "Get",<br/>  "Create",<br/>  "Delete"<br/>]</pre> | no |
| <a name="input_legacy_access_policies_enabled"></a> [legacy\_access\_policies\_enabled](#input\_legacy\_access\_policies\_enabled) | Specifies whether legacy access policies are enabled for this Key Vault. Prevents use of Azure RBAC for data plane. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure location where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_lock"></a> [lock](#input\_lock) | The lock level to apply to the Key Vault. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`. | <pre>object({<br/>    kind = string<br/>    name = optional(string, null)<br/>  })</pre> | `null` | no |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | The network ACL configuration for the Key Vault.<br/>If not specified then the Key Vault will be created with a firewall that blocks access.<br/>Specify `null` to create the Key Vault with no firewall.<br/><br/>- `bypass` - (Optional) Should Azure Services bypass the ACL. Possible values are `AzureServices` and `None`. Defaults to `AzureServices`.<br/>- `default_action` - (Optional) The default action when no rule matches. Possible values are `Allow` and `Deny`. Defaults to `Deny`.<br/>- `ip_rules` - (Optional) A list of IP rules in CIDR format. Defaults to `[]`.<br/>- `virtual_network_subnet_ids` - (Optional) When using with Service Endpoints, a list of subnet IDs to associate with the Key Vault. Defaults to `[]`. | <pre>object({<br/>    bypass                     = optional(string, "AzureServices")<br/>    default_action             = optional(string, "Deny")<br/>    ip_rules                   = optional(list(string), [])<br/>    virtual_network_subnet_ids = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_object_id"></a> [object\_id](#input\_object\_id) | The object ID of the user, group, or application that requires access to the Key Vault. | `string` | n/a | yes |
| <a name="input_objective_code"></a> [objective\_code](#input\_objective\_code) | 4 letter abbreviation of the objective of the resource | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Specifies whether public access is permitted. | `bool` | `false` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Specifies whether protection against purge is enabled for this Key Vault. Note once enabled this cannot be disabled. | `bool` | `true` | no |
| <a name="input_region_code"></a> [region\_code](#input\_region\_code) | 3 letter Region code (e.g., EU2 for East US 2) | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The resource group where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_secret_permissions"></a> [secret\_permissions](#input\_secret\_permissions) | List of permissions for secrets in the Key Vault. | `list(string)` | <pre>[<br/>  "Get",<br/>  "List",<br/>  "Set",<br/>  "Delete"<br/>]</pre> | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name of the Key Vault. Default is `premium`. Possible values are `standard` and `premium`. | `string` | `"premium"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to the Key Vault resource. | `map(string)` | `null` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | The Azure tenant ID used for authenticating requests to Key Vault. You can use the `azurerm_client_config` data source to retrieve it. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the AKV |
| <a name="output_name"></a> [name](#output\_name) | The name of the AKV |
<!-- END_TF_DOCS -->