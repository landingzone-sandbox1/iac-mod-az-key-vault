# =============================================================================
# Use case name: Certificate Management Key Vault for SSL/TLS Certificates
# Description: Example showing how to provision an Azure Key Vault for managing
#              SSL/TLS certificates with automated renewal and lifecycle management.
# 
# When to apply it:
#   - Web applications requiring SSL/TLS certificates
#   - API gateways needing certificate management
#   - Microservices architectures with service-to-service TLS
#   - DevOps teams managing certificate lifecycles
#   - Applications requiring automated certificate renewal
# 
# Considerations:
#   - Certificate authorities must be configured for automated issuance
#   - Lifetime actions require proper monitoring and alerting setup
#   - Certificate policies define renewal and security parameters
#   - Applications must be configured to read certificates from Key Vault
#   - RBAC permissions must allow certificate operations for applications
# 
# Variables used:
#   - application_code: "ECOM" - E-commerce application identifier
#   - objective_code: "KVLT" - Key Vault resource type identifier
#   - environment: "P" - Production environment designation
#   - correlative: "02" - Second instance (cert-specific)
#   - tenant_id: Azure AD tenant for authentication
#   - certificates: SSL/TLS certificates for different domains and services
#   - service_principals: Application identities needing certificate access
# =============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Local variables for this example
locals {
  # Application-specific configuration
  app_name = "ecommerce-platform"
  team     = "platform-engineering"

  # Service principals for applications (replace with actual values)
  service_principals = {
    web_frontend  = "11111111-2222-3333-4444-555555555555" # Web app service principal
    api_gateway   = "22222222-3333-4444-5555-666666666666" # API gateway service principal
    microservices = "33333333-4444-5555-6666-777777777777" # Microservices service principal
  }

  # Certificate configurations for different domains and services
  ssl_certificates = {
    "wildcard-ecommerce-com" = {
      name = "wildcard-ecommerce-com"

      certificate_policy = {
        # Use self-signed for example (replace with actual CA in production)
        issuer_parameters = {
          name = "Self" # Use "Unknown" for external CA or specific CA name
        }

        key_properties = {
          exportable = false # Keep private key secure
          key_size   = 2048  # Standard RSA key size
          key_type   = "RSA" # RSA key type
          reuse_key  = false # Generate new key for each renewal
        }

        # Automated renewal configuration
        lifetime_actions = [
          {
            action = {
              action_type = "AutoRenew" # Automatically renew before expiry
            }
            trigger = {
              days_before_expiry = 30 # Renew 30 days before expiration
            }
          },
          {
            action = {
              action_type = "EmailContacts" # Send email notifications
            }
            trigger = {
              days_before_expiry = 14 # Notify 14 days before expiration
            }
          }
        ]

        secret_properties = {
          content_type = "application/x-pkcs12" # PKCS12 format for web servers
        }

        x509_certificate_properties = {
          key_usage = [
            "digitalSignature",
            "keyEncipherment"
          ]
          extended_key_usage = [
            "1.3.6.1.5.5.7.3.1", # Server Authentication
            "1.3.6.1.5.5.7.3.2"  # Client Authentication
          ]
          subject            = "CN=*.ecommerce.com"
          validity_in_months = 12

          subject_alternative_names = {
            dns_names = [
              "*.ecommerce.com",
              "ecommerce.com",
              "www.ecommerce.com",
              "api.ecommerce.com"
            ]
          }
        }
      }

      tags = {
        CertificateType = "SSL/TLS"
        Domain          = "ecommerce.com"
        Usage           = "Web Frontend"
      }
    }

    "api-gateway-cert" = {
      name = "api-gateway-cert"

      certificate_policy = {
        issuer_parameters = {
          name = "Self" # Replace with actual CA
        }

        key_properties = {
          exportable = false
          key_size   = 2048
          key_type   = "RSA"
          reuse_key  = false
        }

        lifetime_actions = [
          {
            action = {
              action_type = "AutoRenew"
            }
            trigger = {
              days_before_expiry = 45 # Longer lead time for API gateway
            }
          }
        ]

        secret_properties = {
          content_type = "application/x-pkcs12"
        }

        x509_certificate_properties = {
          key_usage = [
            "digitalSignature",
            "keyEncipherment"
          ]
          extended_key_usage = [
            "1.3.6.1.5.5.7.3.1" # Server Authentication
          ]
          subject            = "CN=api.ecommerce.com"
          validity_in_months = 6 # Shorter validity for API gateway

          subject_alternative_names = {
            dns_names = [
              "api.ecommerce.com",
              "gateway.ecommerce.com"
            ]
          }
        }
      }

      tags = {
        CertificateType = "SSL/TLS"
        Domain          = "api.ecommerce.com"
        Usage           = "API Gateway"
      }
    }

    "microservice-internal-cert" = {
      name = "microservice-internal-cert"

      certificate_policy = {
        issuer_parameters = {
          name = "Self" # Internal certificates often self-signed
        }

        key_properties = {
          exportable = true # May need to export for microservices
          key_size   = 2048
          key_type   = "RSA"
          reuse_key  = false
        }

        lifetime_actions = [
          {
            action = {
              action_type = "AutoRenew"
            }
            trigger = {
              days_before_expiry = 15 # Shorter cycle for internal certs
            }
          }
        ]

        secret_properties = {
          content_type = "application/x-pem-file" # PEM format for microservices
        }

        x509_certificate_properties = {
          key_usage = [
            "digitalSignature",
            "keyEncipherment"
          ]
          extended_key_usage = [
            "1.3.6.1.5.5.7.3.1", # Server Authentication
            "1.3.6.1.5.5.7.3.2"  # Client Authentication
          ]
          subject            = "CN=microservices.internal"
          validity_in_months = 3 # Short validity for internal services

          subject_alternative_names = {
            dns_names = [
              "microservices.internal",
              "*.microservices.internal"
            ]
          }
        }
      }

      tags = {
        CertificateType = "SSL/TLS"
        Domain          = "microservices.internal"
        Usage           = "Internal Service-to-Service"
      }
    }
  }
}

# Main Key Vault module invocation for certificate management
module "certificate_keyvault" {
  source = "../../" # Path to the Key Vault module

  # 1. Location - Auto-maps to region code (CUS)
  location = "Central US"

  # 2. Naming convention following BCP standards
  naming = {
    application_code = "ECOM" # E-commerce Platform
    objective_code   = "KVLT" # Key Vault
    environment      = "P"    # Production
    correlative      = "02"   # Second instance (certificate-specific)
  }

  # 3. Complete Key Vault configuration for certificate management
  keyvault_config = {
    # Required: Azure tenant ID
    tenant_id = data.azurerm_client_config.current.tenant_id

    # Standard SKU sufficient for certificate management
    sku_name = "standard"

    # Certificate-focused security configuration
    enabled_for_deployment          = true  # Allow VM access to certificates
    enabled_for_disk_encryption     = false # Not needed for certificates
    enabled_for_template_deployment = true  # Allow ARM template certificate access
    public_network_access_enabled   = true  # Needed for certificate authorities
    purge_protection_enabled        = true  # Protect certificates from deletion
    soft_delete_retention_days      = 90    # Standard retention

    # Moderate network security (CA access required)
    network_acls = {
      bypass                     = "AzureServices"
      default_action             = "Allow" # Allow for certificate authority access
      ip_rules                   = []
      virtual_network_subnet_ids = []
    }

    # RBAC assignments for certificate operations
    role_assignments = {
      # Web frontend - can read certificates
      "web-frontend-cert-user" = {
        role_definition_id_or_name = "Key Vault Certificate User"
        principal_id               = local.service_principals.web_frontend
        principal_type             = "ServicePrincipal"
        description                = "Web frontend certificate access"
      }

      # API Gateway - can read certificates
      "api-gateway-cert-user" = {
        role_definition_id_or_name = "Key Vault Certificate User"
        principal_id               = local.service_principals.api_gateway
        principal_type             = "ServicePrincipal"
        description                = "API gateway certificate access"
      }

      # Microservices - can read certificates
      "microservices-cert-user" = {
        role_definition_id_or_name = "Key Vault Certificate User"
        principal_id               = local.service_principals.microservices
        principal_type             = "ServicePrincipal"
        description                = "Microservices certificate access"
      }

      # Platform engineering - can manage certificates
      "platform-cert-officer" = {
        role_definition_id_or_name = "Key Vault Certificates Officer"
        principal_id               = data.azurerm_client_config.current.object_id
        principal_type             = "User"
        description                = "Platform engineering certificate management"
      }
    }

    # SSL/TLS certificates for the platform
    certificates = local.ssl_certificates

    # Resource lock to prevent accidental deletion
    lock = {
      kind = "CanNotDelete"
      name = "certificate-protection-lock"
    }

    # Tags for certificate management and compliance
    tags = {
      Environment      = "Production"
      Application      = local.app_name
      Team             = local.team
      Purpose          = "Certificate Management"
      CertificateScope = "SSL/TLS"
      AutoRenewal      = "Enabled"
      CostCenter       = "ECOM-INFRA-001"
      ComplianceReq    = "TLS 1.2+"
      MonitoringLevel  = "standard"
    }
  }
}

# Outputs for certificate integration
output "keyvault_id" {
  description = "The ID of the certificate Key Vault"
  value       = module.certificate_keyvault.key_vault_id
}

output "keyvault_uri" {
  description = "The URI of the Key Vault for certificate access"
  value       = module.certificate_keyvault.key_vault_uri
}

output "certificate_list" {
  description = "List of certificates managed in this Key Vault"
  value = {
    for cert_name, cert_config in local.ssl_certificates : cert_name => {
      name         = cert_config.name
      subject      = cert_config.certificate_policy.x509_certificate_properties.subject
      domains      = cert_config.certificate_policy.x509_certificate_properties.subject_alternative_names.dns_names
      validity     = "${cert_config.certificate_policy.x509_certificate_properties.validity_in_months} months"
      auto_renewal = "Enabled"
    }
  }
}

output "certificate_endpoints" {
  description = "Certificate access endpoints for applications"
  value = {
    wildcard_cert_url    = "${module.certificate_keyvault.key_vault_uri}certificates/wildcard-ecommerce-com"
    api_gateway_cert_url = "${module.certificate_keyvault.key_vault_uri}certificates/api-gateway-cert"
    internal_cert_url    = "${module.certificate_keyvault.key_vault_uri}certificates/microservice-internal-cert"
  }
  sensitive = false
}
