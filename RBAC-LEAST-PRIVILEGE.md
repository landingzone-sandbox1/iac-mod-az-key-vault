# Key Vault RBAC Least-Privilege Enforcement

This module enforces least-privilege RBAC principles for Azure Key Vault by restricting role assignments to only approved roles.

## Enforced Least-Privilege Roles

The module allows only the following roles, defined in `local.keyvault_rbac_roles`:

| Role Name | Role UUID | Purpose |
|-----------|-----------|---------|
| Key Vault Reader | `21090545-7ca7-4776-b22c-e363652d74d2` | Read metadata (recommended) |
| Key Vault Secrets User | `4633458b-17de-408a-b874-0445c86b69e6` | Read secrets only |
| Key Vault Crypto User | `12338af0-0e69-4776-bea7-57ae8d297424` | Cryptographic operations only |
| Key Vault Certificate User | `db79e9a7-68ee-4b58-9aeb-b90e7c24fcba` | Certificate operations only |

## Administrative Roles (Use Sparingly)

These administrative roles are allowed but should be used only when necessary:

- **Key Vault Administrator**: Full access (use for break-glass scenarios)
- **Key Vault Contributor**: Management operations (use for deployment automation)

## How Enforcement Works

1. **Variable Validation**: The `variables.tf` file validates that only approved roles are specified in `keyvault_config.role_assignments`.

2. **Local Processing**: The `local.tf` file processes role assignments in `processed_role_assignments`, filtering out any assignments with unapproved roles.

3. **Resource Creation**: Only validated and approved role assignments are created by `azurerm_role_assignment.this` in `main.tf`.

## Example Usage

```hcl
role_assignments = {
  "developer_secrets" = {
    role_definition_id_or_name = "Key Vault Secrets User"
    principal_id               = "user-object-id"
    principal_type             = "User"
    description               = "Developer access to secrets only"
  }
  
  "crypto_service" = {
    role_definition_id_or_name = "Key Vault Crypto User"
    principal_id               = "service-principal-id"  
    principal_type             = "ServicePrincipal"
    description               = "Service account for encryption operations"
  }
}
```

## Benefits

- **Security**: Prevents overprivileged access to Key Vault
- **Compliance**: Ensures adherence to least-privilege principles
- **Auditability**: Clear documentation of allowed roles and their purposes
- **Flexibility**: Supports both role names and UUIDs for compatibility

## Customization

To add additional approved roles, update the `keyvault_rbac_roles` local in `local.tf` and the validation rules in `variables.tf`.
