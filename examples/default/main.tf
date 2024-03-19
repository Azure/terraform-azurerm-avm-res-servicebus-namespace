terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
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
  name = module.naming.resource_group.name_unique
  #location = module.regions.regions[random_integer.region_index.result].name
  location = "uksouth"
}

module "servicebus" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"

  resource_group_name = azurerm_resource_group.this.name

  sku                           = "Premium"
  location                      = "uksouth"
  name                          = "bry-sb-module"
  capacity                      = 2
  local_auth_enabled            = false
  minimum_tls_version           = "1.1"
  public_network_access_enabled = false
  premium_messaging_partitions  = 2
  zone_redundant                = true
  enable_telemetry              = true

  private_endpoints_manage_dns_zone_group = true

  tags = {
    environment = "testing"
    owner       = "bryan"
  }

  network_rule_config = {
    trusted_services_allowed = true
    default_action           = "Allow"
    cidr_or_ip_rules         = ["168.125.123.255", "170.0.0.0/24"]

    network_rules = [
      {
        ignore_missing_vnet_service_endpoint = false
        subnet_id                            = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"
      }
    ]
  }

  diagnostic_settings = {
    diagnostic1 = {
      log_groups    = ["allLogs"]
      metric_groups = ["AllMetrics"]

      name                           = "diagtest1"
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.OperationalInsights/workspaces/brytesting"
    }

    diagnostic2 = {
      log_groups    = ["audit"]
      metric_groups = ["AllMetrics"]

      name                                     = "diagtest2"
      log_analytics_destination_type           = "Dedicated"
      event_hub_name                           = "brytesthub"
      event_hub_authorization_rule_resource_id = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.EventHub/namespaces/brytest/authorizationRules/RootManageSharedAccessKey"
    }

    diagnostic3 = {
      log_categories = ["ApplicationMetricsLogs", "RuntimeAuditLogs", "VNetAndIPFilteringLogs", "OperationalLogs"]
      metric_groups  = ["AllMetrics"]

      name                           = "diagtest3"
      log_analytics_destination_type = "Dedicated"
      storage_account_resource_id    = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.Storage/storageAccounts/brytest"
    }
  }

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = ["/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.ManagedIdentity/userAssignedIdentities/brytest"]
  }

  customer_managed_key = {
    infrastructure_encryption_enabled  = true
    key_name                           = "customermanagedkey"
    key_version                        = "03c89971825b4a0d84905c3597512260"
    key_vault_resource_id              = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.KeyVault/vaults/brytest"
    user_assigned_identity_resource_id = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.ManagedIdentity/userAssignedIdentities/brytest"
  }

  role_assignments = {
    key = {
      skip_service_principal_aad_check = false
      role_definition_id_or_name       = "Contributor"
      description                      = "This is a test role assignment"
      principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
    }
  }

  lock = {
    kind = "CanNotDelete"
    name = "Testing name CanNotDelete"
  }

  queues = {
    forwardQueue = {

    }

    testQueue = {
      auto_delete_on_idle                     = "PT5M"
      dead_lettering_on_message_expiration    = true
      default_message_ttl                     = "PT5M"
      duplicate_detection_history_time_window = "PT5M"
      enable_batched_operations               = true
      enable_express                          = false
      enable_partitioning                     = true
      lock_duration                           = "PT5M"
      requires_duplicate_detection            = true
      requires_session                        = true
      max_delivery_count                      = 10
      max_message_size_in_kilobytes           = 1024
      max_size_in_megabytes                   = 1024
      status                                  = "Active"
      # forward_to                              = "forwardQueue"
      # forward_dead_lettered_messages_to       = "forwardQueue"
      authorization_rules = {
        testRule = {
          send   = true
          listen = true
          manage = true
        }
      }
    }
  }

  private_endpoints = {
    pe1 = {
      role_assignments = {
        key = {
          role_definition_id_or_name = "Contributor"
          description                = "This is a test role assignment"
          principal_id               = "eb5260bd-41f3-4019-9e03-606a617aec13"
        }
      }

      lock = {
        kind = "CanNotDelete"
        name = "Testing name CanNotDelete"
      }

      tags = {
        environment = "testing"
        owner       = "bryan"
      }

      subnet_resource_id = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"
      private_dns_zone_resource_ids = [
        "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
      ]
      application_security_group_associations = {
        asg1 = "/subscriptions/3fdce3cb-f4a5-4c17-99a2-bce02bb0f0c9/resourceGroups/module-dependencies/providers/Microsoft.Network/applicationSecurityGroups/brytest"
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
  }
}
