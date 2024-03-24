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
  prefix               = "diag"
  event_hub_namespace  = "brytest2"
  storage_account_name = "brytest2"

  skus = ["Basic", "Standard", "Premium"]
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

  for_each = toset(local.skus)

  sku                 = each.value
  resource_group_name = azurerm_resource_group.this.name
  location            = module.regions.regions[random_integer.region_index.result].name
  name                = "${module.naming.servicebus_namespace.name_unique}-${each.value}-${local.prefix}"

  diagnostic_settings = {
    diagnostic1 = {
      log_groups    = ["allLogs"]
      metric_groups = ["AllMetrics"]

      name                           = "diagtest1"
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.OperationalInsights/workspaces/brytesting"
    }

    diagnostic2 = {
      log_groups    = ["audit"]
      metric_groups = ["AllMetrics"]

      name                                     = "diagtest2"
      log_analytics_destination_type           = "Dedicated"
      event_hub_name                           = "brytesthub"
      event_hub_authorization_rule_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.EventHub/namespaces/${local.event_hub_namespace}/authorizationRules/RootManageSharedAccessKey"
    }

    diagnostic3 = {
      log_categories = ["ApplicationMetricsLogs", "RuntimeAuditLogs", "VNetAndIPFilteringLogs", "OperationalLogs"]
      metric_groups  = ["AllMetrics"]

      name                           = "diagtest3"
      log_analytics_destination_type = "Dedicated"
      storage_account_resource_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Storage/storageAccounts/${local.storage_account_name}"
    }
  }
}
