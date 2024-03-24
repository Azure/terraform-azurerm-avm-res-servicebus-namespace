terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  prefix   = "cmk-auto"
  key_name = "customermanagedkey"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_resource_group" "example" {
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  location = module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "example-${local.prefix}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.5.3"

  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  name                          = "${module.naming.key_vault.name_unique}${local.prefix}"
  purge_protection_enabled      = true
  public_network_access_enabled = true

  network_acls = {
    default_action = "Allow"
  }

  keys = {
    cmk = {
      key_opts = [
        "wrapKey",
        "unwrapKey"
      ]

      key_size     = 4096
      key_type     = "RSA"
      name         = local.key_name
      key_vault_id = module.key_vault.resource.id
    }
  }

  role_assignments = {
    cmk_user_mi = {
      role_definition_id_or_name = "Key Vault Crypto User"
      principal_id               = azurerm_user_assigned_identity.example.principal_id
    }
  }
}

module "servicebus" {
  source = "../../"

  sku                 = "Premium"
  resource_group_name = azurerm_resource_group.example.name
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = "${module.naming.servicebus_namespace.name_unique}-${local.prefix}"

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example.id]
  }

  customer_managed_key = {
    infrastructure_encryption_enabled  = true
    key_name                           = local.key_name
    key_vault_resource_id              = module.key_vault.resource.id
    user_assigned_identity_resource_id = azurerm_user_assigned_identity.example.id
  }

  depends_on = [module.key_vault]
}