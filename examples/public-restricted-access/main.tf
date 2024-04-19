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

locals {
  prefix = "resPub"
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
  location = module.regions.regions[random_integer.region_index.result].name
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.1.4"

  virtual_network_address_space = ["10.0.0.0/16"]
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  name                          = "${module.naming.virtual_network.name_unique}-${local.prefix}"

  subnets = {
    default = {
      address_prefixes  = ["10.0.0.0/24"]
      service_endpoints = ["Microsoft.ServiceBus"]
    }
  }
}

module "servicebus" {
  source = "../../"

  sku                           = "Premium"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  name                          = "${module.naming.servicebus_namespace.name_unique}-${local.prefix}"
  public_network_access_enabled = true

  network_rule_config = {
    trusted_services_allowed = true
    default_action           = "Deny"
    cidr_or_ip_rules         = ["168.125.123.255", "170.0.0.0/24"]

    network_rules = [
      {
        subnet_id = module.vnet.subnets.default.id
      }
    ]
  }
}
