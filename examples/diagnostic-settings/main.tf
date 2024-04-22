terraform {
  required_version = "~> 1.5"

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

locals {
  prefix = "diag"
  skus   = ["Basic", "Standard", "Premium"]
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"

  recommended_regions_only = true
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
  location = "westeurope" # This test case in Premium SKU is not supported in some of the recommended regions. Pinned to an specific one to make the test more reliable. #module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_storage_account" "example" {
  name = "${module.naming.storage_account.name_unique}${local.prefix}"

  account_replication_type = "ZRS"
  account_tier             = "Standard"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
}

resource "azurerm_log_analytics_workspace" "example" {
  name = "${module.naming.log_analytics_workspace.name_unique}-${local.prefix}"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_eventhub_namespace" "example" {
  name = "${module.naming.eventhub_namespace.name_unique}-${local.prefix}"

  sku                 = "Basic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_eventhub" "example" {
  name = "diagnosticshub"

  partition_count     = 2
  message_retention   = 1
  resource_group_name = azurerm_resource_group.example.name
  namespace_name      = azurerm_eventhub_namespace.example.name
}

module "servicebus" {
  source = "../../"

  for_each = toset(local.skus)

  sku                 = each.value
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  name                = "${module.naming.servicebus_namespace.name_unique}-${each.value}-${local.prefix}"

  diagnostic_settings = {
    diagnostic1 = {
      log_groups    = ["allLogs"]
      metric_groups = ["AllMetrics"]

      name                           = "diagtest1"
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = azurerm_log_analytics_workspace.example.id
    }

    diagnostic2 = {
      log_groups    = ["audit"]
      metric_groups = ["AllMetrics"]

      name                                     = "diagtest2"
      log_analytics_destination_type           = "Dedicated"
      event_hub_name                           = azurerm_eventhub.example.name
      event_hub_authorization_rule_resource_id = "${azurerm_eventhub_namespace.example.id}/authorizationRules/RootManageSharedAccessKey"
    }

    diagnostic3 = {
      log_categories = ["ApplicationMetricsLogs", "RuntimeAuditLogs", "VNetAndIPFilteringLogs", "OperationalLogs"]
      metric_groups  = ["AllMetrics"]

      name                           = "diagtest3"
      log_analytics_destination_type = "Dedicated"
      storage_account_resource_id    = azurerm_storage_account.example.id
    }
  }
}
