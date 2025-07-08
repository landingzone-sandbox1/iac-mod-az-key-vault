# Basic Key Vault Provisioning Example

## Use Case
**Basic Azure Key Vault Provisioning for Development Environment**

This example demonstrates how to provision a basic Azure Key Vault with RBAC, secrets, and keys for development teams using BCP naming conventions.

## When to Apply
Use this example when setting up a development Key Vault with basic security features and sample content for:
- Development team Key Vault setup
- Testing Key Vault functionality
- Learning BCP naming conventions
- Demonstrating least-privilege RBAC

## Prerequisites
- Azure CLI or PowerShell authenticated
- Appropriate Azure permissions to create Resource Groups, Key Vaults, and Role Assignments
- Terraform 1.9 or later
- AzureRM provider 4.28 or later

## Variables and Configuration

### Input Variables (from example.auto.tfvars)
- **location**: Azure region for deployment (default: "East US 2")
- **environment**: Environment code (default: "D" for Development)

### Locals Configuration
The example uses locals to define:
- **BCP Naming Components**: application_code="FINC", objective_code="SEC", correlative="01"
- **Region Mapping**: Maps location to BCP region codes (EU2, WU2, etc.)
- **Corporate IP Ranges**: Allowed network access ranges
- **Sample Content**: Demonstration secrets and keys
- **RBAC Configuration**: Current user principal ID from data source

### Data Sources
- **azurerm_client_config**: Auto-detects current Azure context for tenant ID and user principal ID

Example: `AZKVEUS2DEMOKLT D01`
- `AZKV` = Azure Key Vault service code
- `EUS2` = East US 2 region code (auto-generated from location)
- `DEMO` = Application code
- `KVLT` = Objective code (Key Vault)
- `D` = Development environment
- `01` = Correlative (instance number)

## Examples

### 1. Simple Example (`simple-example.tf`)

**Purpose**: Minimal configuration for development and learning
**Features**:
- Basic Key Vault with RBAC
- Current user access
- Development-friendly settings

```bash
# Run the simple example
terraform init
terraform plan -var="environment=D"
terraform apply
```

### 2. Comprehensive Example (`example.tf`)

**Purpose**: Production-ready examples with all features
**Features**:
- Multiple Key Vaults for different use cases
- Keys with rotation policies
- Secrets with expiration
- Network ACLs and security
- Resource locks
- Comprehensive RBAC

```bash
# Run the comprehensive example
terraform init
terraform plan -var="environment=P" -var="location=East US 2"
terraform apply
```

## Example Use Cases

### Financial Services Key Vault
```hcl
naming = {
  application_code = "FINC"  # Finance application
  environment      = "P"     # Production
  correlative      = "01"    # First instance
  objective_code   = "SEC"   # Security vault
}
```

### API Services Key Vault
```hcl
naming = {
  application_code = "APID"  # API Gateway
  environment      = "P"     # Production  
  correlative      = "01"    # First instance
  objective_code   = "ENC"   # Encryption vault
}
```

### Development Testing
```hcl
naming = {
  application_code = "DEMO"  # Demo application
  environment      = "D"     # Development
  correlative      = "01"    # First instance
  objective_code   = "TST"   # Testing vault
}
```

## Supported Regions (Americas Only)

The module is configured for Americas regions only:

**North America**:
- East US, East US 2, Central US, North Central US, South Central US
- West US, West US 2, West US 3
- Canada Central, Canada East

**South America**:
- Brazil South, Brazil Southeast
- Mexico Central, Chile Central

## Variables

### Required Variables

```hcl
variable "location" {
  description = "Azure region (Americas only)"
  type        = string
}

variable "naming" {
  description = "BCP naming convention"
  type = object({
    application_code = string  # 4 characters
    environment      = string  # P, C, D, F
    correlative      = string  # 2 digits
    objective_code   = string  # 3-4 characters
  })
}

variable "keyvault_config" {
  description = "Key Vault configuration"
  type = object({
    tenant_id = string
    # ... additional configuration options
  })
}
```

## RBAC Roles (Least Privilege)

The module supports these least-privilege roles:

- **Key Vault Reader** - Read metadata only
- **Key Vault Secrets User** - Read secrets
- **Key Vault Secrets Officer** - Manage secrets
- **Key Vault Crypto User** - Use keys for crypto operations
- **Key Vault Crypto Officer** - Manage keys
- **Key Vault Certificate User** - Read certificates
- **Key Vault Certificate Officer** - Manage certificates

## Common Commands

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Destroy resources
terraform destroy

# Format code
terraform fmt

# Validate configuration
terraform validate
```

## Troubleshooting

### Common Issues

1. **Region not supported**: Ensure you're using an Americas region
2. **Naming validation**: Follow BCP naming patterns
3. **RBAC permissions**: Use least-privilege roles only
4. **Tenant ID**: Use `data.azurerm_client_config.current.tenant_id`

### Validation

```bash
# Check for errors
terraform validate

# Plan without applying
terraform plan

# Check formatting
terraform fmt -check
```

## Security Best Practices

1. **Use least-privilege RBAC roles**
2. **Enable purge protection in production**
3. **Configure network ACLs appropriately**
4. **Use private endpoints for sensitive workloads**
5. **Implement key rotation policies**
6. **Set appropriate secret expiration dates**
7. **Use resource locks to prevent accidental deletion**

## Support

For issues or questions about the Key Vault module:

1. Check the main module documentation
2. Review these examples
3. Validate your configuration matches the interface
4. Ensure you're using supported regions and naming conventions

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.28 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.28.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_keyvault_basic"></a> [keyvault\_basic](#module\_keyvault\_basic) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code (D=Development, C=Certification, P=Production, F=Functional) | `string` | `"D"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for deployment | `string` | `"East US 2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_keyvault_info"></a> [keyvault\_info](#output\_keyvault\_info) | Key Vault information for development team |
| <a name="output_rbac_assignments"></a> [rbac\_assignments](#output\_rbac\_assignments) | RBAC assignments created for the Key Vault (not available: module does not export this output) |
| <a name="output_security_compliance"></a> [security\_compliance](#output\_security\_compliance) | Security compliance status |
<!-- END_TF_DOCS -->