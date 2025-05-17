terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.28.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_keys    = true
      recover_soft_deleted_certificates = true
      recover_soft_deleted_secrets = true
    }
  }
}