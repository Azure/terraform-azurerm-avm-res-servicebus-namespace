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
  prefix                  = "cmk"
  key_vault_name          = "brytest2"
  customer_managed_key_id = "b975a2e3f7a84290a31c9362c99627f7"
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

resource "azurerm_resource_group" "this" {
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  location = module.regions.regions[random_integer.region_index.result].name
}

module "servicebus" {
  source = "../../"

  sku                 = "Premium"
  resource_group_name = azurerm_resource_group.this.name
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = "${module.naming.servicebus_namespace.name_unique}-${local.prefix}"

  customer_managed_key = {
    infrastructure_encryption_enabled  = true
    key_name                           = "customermanagedkey"
    key_version                        = local.customer_managed_key_id
    key_vault_resource_id              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.KeyVault/vaults/${local.key_vault_name}"
    user_assigned_identity_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.ManagedIdentity/userAssignedIdentities/brytest"
  }
}
