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
  prefix = "pe"
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

  sku                           = "Premium"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = module.regions.regions[random_integer.region_index.result].name
  name                          = "${module.naming.servicebus_namespace.name_unique}-${each.value}-${local.prefix}"
  public_network_access_enabled = false

  private_endpoints = {
    max = {
      name                        = "max"
      private_dns_zone_group_name = "max_group"

      role_assignments = {
        key = {
          role_definition_id_or_name = "Contributor"
          description                = "This is a test role assignment"
          principal_id               = data.azurerm_client_config.current.object_id
        }
      }

      # lock = {
      #   kind = "CanNotDelete"
      #   name = "Testing name CanNotDelete"
      # }

      tags = {
        environment = "testing"
        department  = "engineering"
      }

      subnet_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"

      application_security_group_associations = {
        asg1 = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/applicationSecurityGroups/brytest"
      }

      network_interface_name = "nic1"
      # ip_configurations = {
      #   ipconfig1 = {
      #     name               = "ipconfig1"
      #     group_id           = "vault"
      #     member_name        = "default"
      #     private_ip_address = "10.0.0.7"
      #   }
      # }
    }

    noDnsGroup = {
      name               = "noDnsGroup"
      subnet_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"
    }

    withDnsGroup = {
      name                        = "wishDnsGroup"
      private_dns_zone_group_name = "withDnsGroup_group"

      subnet_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"
      private_dns_zone_resource_ids = [
        "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
      ]
    }
  }
}
