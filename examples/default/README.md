<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
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

data "azurerm_client_config" "current" {}

locals {
  key_vault_name          = "brytest2"
  event_hub_namespace     = "brytest2"
  storage_account_name    = "brytest2"
  customer_managed_key_id = "b975a2e3f7a84290a31c9362c99627f7"

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
  name = module.naming.resource_group.name_unique
  #location = module.regions.regions[random_integer.region_index.result].name
  location = "uksouth"
}

module "servicebus" {
  source = "../../"

  for_each = toset(local.skus)

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"

  resource_group_name = azurerm_resource_group.this.name

  location                      = "uksouth"
  sku                           = each.value
  name                          = "${module.naming.servicebus_namespace.name_unique}-${each.value}"
  capacity                      = 2
  local_auth_enabled            = true
  minimum_tls_version           = "1.1"
  public_network_access_enabled = true
  premium_messaging_partitions  = 2
  zone_redundant                = true
  enable_telemetry              = true

  private_endpoints_manage_dns_zone_group = true

  authorization_rules = {
    testRule = {
      send   = true
      listen = true
      manage = true
    }
  }

  tags = {
    environment = "testing"
    department  = "engineering"
  }

  network_rule_config = {
    trusted_services_allowed = true
    default_action           = "Deny"
    cidr_or_ip_rules         = ["168.125.123.255", "170.0.0.0/24"]

    network_rules = [
      {
        ignore_missing_vnet_service_endpoint = false
        subnet_id                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"
      }
    ]
  }

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

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.ManagedIdentity/userAssignedIdentities/brytest"]
  }

  customer_managed_key = {
    infrastructure_encryption_enabled  = true
    key_name                           = "customermanagedkey"
    key_version                        = local.customer_managed_key_id
    key_vault_resource_id              = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.KeyVault/vaults/${local.key_vault_name}"
    user_assigned_identity_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.ManagedIdentity/userAssignedIdentities/brytest"
  }

  role_assignments = {
    key = {
      skip_service_principal_aad_check = false
      role_definition_id_or_name       = "Contributor"
      description                      = "This is a test role assignment"
      principal_id                     = data.azurerm_client_config.current.object_id
    }
  }

  lock = {
    kind = "CanNotDelete"
    name = "Testing name CanNotDelete"
  }

  queues = {
    forwardQueue = {

    }

    fromForwardQueue = {
      requires_session                  = false
      forward_to                        = "forwardQueue"
      forward_dead_lettered_messages_to = "forwardQueue"
    }

    enableExpressQueue = {
      enable_express               = true
      requires_duplicate_detection = false
    }

    testQueue = {
      auto_delete_on_idle                     = "P7D"
      dead_lettering_on_message_expiration    = true
      default_message_ttl                     = "PT5M"
      duplicate_detection_history_time_window = "PT5M"
      enable_batched_operations               = true
      enable_express                          = false
      enable_partitioning                     = true
      lock_duration                           = "PT1M"
      requires_duplicate_detection            = true
      requires_session                        = true
      max_delivery_count                      = 100
      max_message_size_in_kilobytes           = 1024
      max_size_in_megabytes                   = 1024
      status                                  = "Active"

      role_assignments = {
        key = {
          skip_service_principal_aad_check = false
          role_definition_id_or_name       = "Contributor"
          description                      = "This is a test role assignment"
          principal_id                     = data.azurerm_client_config.current.object_id
        }
      }

      authorization_rules = {
        testRule = {
          send   = true
          listen = true
          manage = true
        }
      }
    }
  }

  topics = {
    forwardTopic = {
    }

    enableExpressTopic = {
      enable_express               = true
      requires_duplicate_detection = false
    }

    testTopic = {
      auto_delete_on_idle                     = "P7D"
      default_message_ttl                     = "PT5M"
      duplicate_detection_history_time_window = "PT5M"
      enable_batched_operations               = true
      enable_express                          = false
      enable_partitioning                     = true
      requires_duplicate_detection            = null
      max_message_size_in_kilobytes           = 1024
      max_size_in_megabytes                   = 1024
      status                                  = "Active"
      support_ordering                        = true

      role_assignments = {
        key = {
          skip_service_principal_aad_check = false
          role_definition_id_or_name       = "Contributor"
          description                      = "This is a test role assignment"
          principal_id                     = data.azurerm_client_config.current.object_id
        }
      }

      subscriptions = {
        testSubscription = {
          dead_lettering_on_filter_evaluation_error = true
          dead_lettering_on_message_expiration      = true
          default_message_ttl                       = "PT5M"
          enable_batched_operations                 = true
          lock_duration                             = "PT1M"
          max_delivery_count                        = 100
          status                                    = "Active"
          auto_delete_on_idle                       = "P7D"
          requires_session                          = true
        }

        fromForwardSubscription = {
          requires_session                  = false
          forward_to                        = "forwardTopic"
          forward_dead_lettered_messages_to = "forwardTopic"
        }
      }

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
      name                        = "pep1"
      private_dns_zone_group_name = "pep1_group"

      role_assignments = {
        key = {
          role_definition_id_or_name = "Contributor"
          description                = "This is a test role assignment"
          principal_id               = data.azurerm_client_config.current.object_id
        }
      }

      lock = {
        kind = "CanNotDelete"
        name = "Testing name CanNotDelete"
      }

      tags = {
        environment = "testing"
        department  = "engineering"
      }

      subnet_resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/virtualNetworks/brytest/subnets/default"
      private_dns_zone_resource_ids = [
        "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/module-dependencies/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"
      ]
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
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

### <a name="module_servicebus"></a> [servicebus](#module\_servicebus)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->