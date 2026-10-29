override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    output = {
      properties = {
        serviceBusEndpoint = "https://test-namespace.servicebus.windows.net:443/"
      }
    }
  }
}

mock_provider "azurerm" {
  mock_resource "azurerm_servicebus_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/orders"
    }
  }
  mock_resource "azurerm_servicebus_topic" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/events"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

override_data {
  target = data.azapi_resource_list.role_definitions
  values = {
    output = {
      results = [
        {
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419"
          role_name = "Azure Service Bus Data Owner"
        },
        {
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0"
          role_name = "Azure Service Bus Data Receiver"
        },
      ]
    }
  }
}

override_data {
  target = data.azapi_resource_list.diagnostic_categories
  values = {
    output = {
      categories = [
        { name = "OperationalLogs", category_type = "Logs", groups = ["audit", "allLogs"] },
        { name = "VNetAndIPFilteringLogs", category_type = "Logs", groups = ["allLogs"] },
        { name = "AllMetrics", category_type = "Metrics", groups = null },
      ]
    }
  }
}

variables {
  enable_telemetry    = false
  name                = "test-namespace"
  location            = "westeurope"
  resource_group_name = "test"
  sku                 = "Standard"
}

run "lock_keeps_azurerm_name_and_notes" {
  command = apply

  variables {
    lock = {
      kind = "ReadOnly"
    }
  }

  assert {
    condition     = azapi_resource.lock["Namespace"].name == "lock-ReadOnly" && azapi_resource.lock["Namespace"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    error_message = "The namespace lock MUST keep the lock-<kind> name and be scoped to the namespace."
  }

  assert {
    condition     = azapi_resource.lock["Namespace"].body.properties.level == "ReadOnly" && azapi_resource.lock["Namespace"].body.properties.notes == "Cannot delete or modify the resource or its child resources."
    error_message = "The lock level and notes MUST match the azurerm resource."
  }

  assert {
    condition     = output.resource_locks["Namespace"].lock_level == "ReadOnly" && output.resource_locks["Namespace"].scope == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    error_message = "resource_locks MUST keep the azurerm attribute names."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "no_lock_by_default" {
  command = plan

  assert {
    condition     = length(azapi_resource.lock) == 0 && length(time_sleep.lock_removal) == 0
    error_message = "No lock MUST be planned when var.lock is null."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "role_assignments_on_namespace_queue_and_topic" {
  command = apply

  variables {
    role_assignments = {
      owner = {
        role_definition_id_or_name = "azure service bus data owner"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      tenant_level_id = {
        role_definition_id_or_name       = "/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419"
        principal_id                     = "00000000-0000-0000-0000-000000000002"
        skip_service_principal_aad_check = true
      }
    }
    queues = {
      orders = {
        role_assignments = {
          receiver = {
            role_definition_id_or_name = "Azure Service Bus Data Receiver"
            principal_id               = "00000000-0000-0000-0000-000000000003"
          }
        }
      }
    }
    topics = {
      events = {
        role_assignments = {
          receiver = {
            role_definition_id_or_name = "Azure Service Bus Data Receiver"
            principal_id               = "00000000-0000-0000-0000-000000000004"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["Namespace|owner"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419"
    error_message = "Role names MUST resolve case-insensitively to the role definition ID."
  }

  assert {
    condition     = azapi_resource.role_assignments["Namespace|tenant_level_id"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419" && azapi_resource.role_assignments["Namespace|tenant_level_id"].body.properties.principalType == "ServicePrincipal"
    error_message = "Tenant-level IDs MUST be qualified with the subscription, and skip_service_principal_aad_check MUST send ServicePrincipal."
  }

  assert {
    condition     = azapi_resource.role_assignments["Queue|receiver|orders"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/orders"
    error_message = "Queue role assignments MUST be scoped to the queue."
  }

  assert {
    condition     = azapi_resource.role_assignments["Topic|receiver|events"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/events"
    error_message = "Topic role assignments MUST be scoped to the topic."
  }

  assert {
    condition     = output.resource_role_assignments["Namespace|owner"].role_definition_id == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/090c5cfd-751d-490a-894a-3ce6f1109419" && output.resource_role_assignments["Namespace|owner"].principal_id == "00000000-0000-0000-0000-000000000001"
    error_message = "resource_role_assignments MUST keep the azurerm attribute names."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "role_assignment_unknown_name_fails" {
  command = plan

  variables {
    role_assignments = {
      missing = {
        role_definition_id_or_name = "Does Not Exist"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  expect_failures = [azapi_resource.role_assignments["Namespace|missing"]]
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "diagnostic_settings_groups_by_default" {
  command = apply

  variables {
    diagnostic_settings = {
      law = {
        log_groups            = ["audit"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].name == "diag-test-namespace"
    error_message = "The diagnostic setting name MUST default to diag-<name>."
  }

  assert {
    condition = jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.logs) == jsonencode([
      { category = null, categoryGroup = "allLogs", enabled = false },
      { category = null, categoryGroup = "audit", enabled = true },
    ])
    error_message = "Every category group MUST be sent with an explicit enabled flag."
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].body.properties.metrics == tolist([{ category = "AllMetrics", enabled = true }])
    error_message = "Metric categories MUST be sent with an explicit enabled flag."
  }

  assert {
    condition     = output.resource_diagnostic_settings["law"].log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/law"
    error_message = "resource_diagnostic_settings MUST keep the azurerm attribute names."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "diagnostic_settings_categories_win_over_groups" {
  command = apply

  variables {
    diagnostic_settings = {
      law = {
        log_categories        = ["OperationalLogs"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    condition = jsonencode(azapi_resource.diagnostic_settings["law"].body.properties.logs) == jsonencode([
      { category = "OperationalLogs", categoryGroup = null, enabled = true },
      { category = "VNetAndIPFilteringLogs", categoryGroup = null, enabled = false },
    ])
    error_message = "Log categories MUST replace the default category groups, as before."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}
