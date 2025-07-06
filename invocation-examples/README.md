# Azure Key Vault Module - Invocation Examples

This directory contains comprehensive examples demonstrating how to use the Azure Key Vault Terraform module in different scenarios. Each example follows the module-template pattern with only three top-level variables: `location`, `naming`, and `keyvault_config`.

## 📁 **Directory Structure**

```
invocation-examples/
├── basic-keyvault-provisioning/         # Simple Key Vault setup
├── enterprise-keyvault-with-rbac/       # Production RBAC setup
├── development-keyvault-with-keys/      # Development with crypto keys
├── private-endpoint-keyvault/           # Secure private connectivity
├── certificate-management-keyvault/     # SSL/TLS certificate management
└── legacy-access-policies-keyvault/     # Legacy access policies migration
```

## 🎯 **Use Cases Covered**

### 1. **Basic Key Vault Provisioning**
- **Location**: `invocation-examples/basic-keyvault-provisioning/`
- **Description**: Simple Key Vault setup for getting started
- **When to use**: Learning, testing, minimal requirements
- **Key features**: Basic configuration, simple secrets

### 2. **Enterprise Key Vault with RBAC**
- **Location**: `invocation-examples/enterprise-keyvault-with-rbac/`
- **Description**: Production-ready Key Vault with RBAC authorization
- **When to use**: Production environments, enterprise security
- **Key features**: RBAC roles, premium SKU, network restrictions, resource locks

### 3. **Development Key Vault with Cryptographic Keys**
- **Location**: `invocation-examples/development-keyvault-with-keys/`
- **Description**: Development setup with encryption and signing keys
- **When to use**: Development environments, crypto operations testing
- **Key features**: RSA/EC keys, key rotation policies, development-friendly access

### 4. **Secure Key Vault with Private Endpoint**
- **Location**: `invocation-examples/private-endpoint-keyvault/`
- **Description**: Maximum security with private network connectivity
- **When to use**: High-security environments, compliance requirements
- **Key features**: Private endpoints, DNS integration, network isolation

### 5. **Certificate Management Key Vault**
- **Location**: `invocation-examples/certificate-management-keyvault/`
- **Description**: SSL/TLS certificate lifecycle management
- **When to use**: Web applications, API gateways, certificate automation
- **Key features**: Certificate policies, auto-renewal, certificate authorities

### 6. **Legacy Access Policies Key Vault**
- **Location**: `invocation-examples/legacy-access-policies-keyvault/`
- **Description**: Legacy access policies for migration scenarios
- **When to use**: RBAC migration, legacy application compatibility
- **Key features**: Granular permissions, migration guidance, backwards compatibility

## 🚀 **Quick Start**

### Using an Example

1. **Choose your use case** from the directories above
2. **Navigate to the example directory**:
   ```bash
   cd invocation-examples/enterprise-keyvault-with-rbac/
   ```
3. **Review the example file** (`main.tf`) for configuration details
4. **Customize the variables** for your environment:
   - Update `location` to your preferred Azure region
   - Modify `naming` values to match your naming convention
   - Adjust `keyvault_config` based on your requirements
5. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Example Variable Customization

```hcl
# Customize these values for your environment
module "your_keyvault" {
  source = "../../"  # Path to the Key Vault module
  
  # 1. Your Azure region
  location = "East US 2"
  
  # 2. Your naming convention
  naming = {
    application_code = "MYAP"  # Your application code
    objective_code   = "KVLT"  # Key Vault (standard)
    environment      = "P"     # Your environment (D/P/C/F)
    correlative      = "01"    # Instance number
  }
  
  # 3. Your Key Vault configuration
  keyvault_config = {
    tenant_id = data.azurerm_client_config.current.tenant_id
    # ... customize other settings
  }
}
```

## 📋 **Prerequisites**

### General Requirements
- **Azure subscription** with appropriate permissions
- **Terraform** >= 1.0
- **Azure CLI** or **Azure PowerShell** configured
- **Azure AD tenant** access for RBAC configuration

### Specific Requirements by Use Case

| **Use Case** | **Additional Prerequisites** |
|-------------|------------------------------|
| **Basic** | Azure subscription only |
| **Enterprise RBAC** | Service principal IDs, production subscription |
| **Development Keys** | Development environment, testing permissions |
| **Private Endpoint** | Existing VNet, subnet, private DNS zone |
| **Certificate Management** | Certificate authority configuration, domain ownership |
| **Legacy Access Policies** | User/service principal object IDs |

## 🔧 **Configuration Patterns**

### Module Interface (Consistent Across All Examples)

```hcl
module "keyvault_example" {
  source = "../../"
  
  # 1. Location (auto-maps to region code)
  location = "Azure Region Name"
  
  # 2. Naming convention (BCP standards)
  naming = {
    application_code = "XXXX"  # 4-char application code
    objective_code   = "KVLT"  # Resource type (Key Vault)
    environment      = "X"     # D/P/C/F
    correlative      = "XX"    # 2-digit instance number
  }
  
  # 3. Complete Key Vault configuration
  keyvault_config = {
    tenant_id = "..."
    # All other configuration options
  }
}
```

### Common Configuration Options

```hcl
keyvault_config = {
  # Required
  tenant_id = data.azurerm_client_config.current.tenant_id
  
  # Basic Configuration
  sku_name                       = "standard" | "premium"
  enabled_for_deployment         = true | false
  enabled_for_disk_encryption    = true | false
  enabled_for_template_deployment = true | false
  public_network_access_enabled  = true | false
  purge_protection_enabled       = true | false
  soft_delete_retention_days     = 7-90
  
  # Network Security
  network_acls = {
    bypass         = "AzureServices" | "None"
    default_action = "Allow" | "Deny"
    ip_rules       = ["1.2.3.4/32", ...]
    virtual_network_subnet_ids = ["/subscriptions/.../subnets/...", ...]
  }
  
  # Access Control (Choose ONE)
  # Option 1: Modern RBAC (Recommended)
  role_assignments = {
    "role-name" = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id              = "user-or-sp-id"
      principal_type            = "User" | "ServicePrincipal"
    }
  }
  
  # Option 2: Legacy Access Policies
  legacy_access_policies_enabled = true
  legacy_access_policies = {
    "policy-name" = {
      object_id          = "user-or-sp-id"
      key_permissions    = ["Get", "List", ...]
      secret_permissions = ["Get", "Set", ...]
    }
  }
  
  # Resources
  keys = { ... }
  secrets = { ... }
  certificates = { ... }
  private_endpoints = { ... }
  
  # Management
  lock = {
    kind = "CanNotDelete" | "ReadOnly"
    name = "lock-name"
  }
  
  tags = { ... }
}
```

## 🔒 **Security Best Practices**

### Production Environments
- ✅ Use **Premium SKU** for HSM-backed keys
- ✅ Enable **purge protection** to prevent accidental deletion
- ✅ Use **RBAC** instead of legacy access policies
- ✅ Implement **network restrictions** (private endpoints or ACLs)
- ✅ Enable **resource locks** for protection
- ✅ Use **least-privilege** role assignments
- ✅ Configure **key rotation policies**

### Development Environments
- ✅ Use **Standard SKU** for cost efficiency
- ✅ Allow **public network access** for convenience
- ✅ Disable **purge protection** for easy cleanup
- ✅ Use **shorter retention periods**
- ✅ Tag resources as **temporary/development**

### Network Security
```hcl
# Maximum Security (Production)
network_acls = {
  bypass         = "None"
  default_action = "Deny"
  ip_rules       = []  # No public IPs
}
private_endpoints = { ... }  # Use private endpoints

# Moderate Security (Development)
network_acls = {
  bypass         = "AzureServices"
  default_action = "Allow"
  ip_rules       = ["your.office.ip/32"]
}
```

## 📊 **Comparison Matrix**

| **Feature** | **Basic** | **Enterprise** | **Development** | **Private** | **Certificate** | **Legacy** |
|------------|-----------|---------------|---------------|-------------|----------------|------------|
| **SKU** | Standard | Premium | Standard | Premium | Standard | Standard |
| **RBAC** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Access Policies** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Public Access** | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **Private Endpoints** | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Keys** | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| **Secrets** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Certificates** | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Purge Protection** | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Resource Lock** | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |

## 🆘 **Troubleshooting**

### Common Issues

1. **Permission Errors**
   - Ensure your Azure identity has Key Vault Contributor permissions
   - Verify service principal IDs are correct
   - Check Azure AD tenant permissions

2. **Network Access Issues**
   - Review network ACL configuration
   - Verify IP allowlists if using public access
   - Check private endpoint DNS resolution

3. **RBAC vs Access Policy Conflicts**
   - Cannot use both simultaneously
   - Set `legacy_access_policies_enabled = false` for RBAC
   - Set `legacy_access_policies_enabled = true` for access policies

4. **Certificate Issues**
   - Verify certificate authority configuration
   - Check domain ownership for public certificates
   - Review certificate policy settings

### Getting Help

- Review the specific example's comments and configuration
- Check Azure Key Vault documentation
- Verify Terraform Azure Provider documentation
- Test in development environment first

## 📝 **Contributing**

To add new examples:

1. Create new directory under `invocation-examples/`
2. Follow the established comment format at the top of `main.tf`
3. Include comprehensive configuration examples
4. Add appropriate outputs and documentation
5. Update this README with the new use case

---

**Note**: Replace placeholder values (service principal IDs, domain names, etc.) with your actual values before applying these examples in your environment.
