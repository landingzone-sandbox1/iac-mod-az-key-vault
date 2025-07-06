# Key Vault Module Examples

This directory contains examples demonstrating how to use the Azure Key Vault Terraform module with the simplified module-template interface.

## Module Interface

The module follows the **module-template pattern** with:

- **`location`** - Top-level variable for Azure region (auto-maps to region code)
- **`naming`** - Object containing BCP naming convention fields
- **`keyvault_config`** - Object containing all Key Vault configuration

## BCP Naming Convention

The module automatically generates resource names following the BCP standard:

```
{ServiceCode}{RegionCode}{ApplicationCode}{ObjectiveCode}{Environment}{Correlative}
```

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
