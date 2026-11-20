mock_provider "azurerm" {
  alias = "mock"

  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    }
  }
  mock_resource "azurerm_servicebus_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/test-queue"
    }
  }
}

mock_provider "azapi" {
  alias = "mock"
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name                = "test-namespace"
  location            = "westeurope"
  resource_group_name = "test"
  enable_telemetry    = false
  queues = {
    orders = {
      name = "sbq-orders"
      role_assignments = {
        sender = {
          role_definition_id_or_name = "Azure Service Bus Data Sender"
          principal_id               = "00000000-0000-0000-0000-000000000001"
        }
      }
    }
    forwarded = {
      name       = "sbq-forwarded"
      forward_to = "sbq-orders"
      role_assignments = {
        sender = {
          role_definition_id_or_name = "Azure Service Bus Data Sender"
          principal_id               = "00000000-0000-0000-0000-000000000002"
        }
      }
    }
    unnamed = {
      role_assignments = {
        receiver = {
          role_definition_id_or_name = "Azure Service Bus Data Receiver"
          principal_id               = "00000000-0000-0000-0000-000000000003"
        }
      }
    }
  }
}

run "queue_role_assignments_use_queue_name" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock
  }

  assert {
    condition = (
      length(azurerm_role_assignment.this) == 3 &&
      azurerm_role_assignment.this["Queue|sender|sbq-orders"].scope == azurerm_servicebus_queue.base_queues["sbq-orders"].id &&
      azurerm_role_assignment.this["Queue|sender|sbq-orders"].principal_id == "00000000-0000-0000-0000-000000000001" &&
      azurerm_role_assignment.this["Queue|sender|sbq-forwarded"].scope == azurerm_servicebus_queue.forward_queues["sbq-forwarded"].id &&
      azurerm_role_assignment.this["Queue|sender|sbq-forwarded"].principal_id == "00000000-0000-0000-0000-000000000002" &&
      azurerm_role_assignment.this["Queue|receiver|unnamed"].scope == azurerm_servicebus_queue.base_queues["unnamed"].id &&
      azurerm_role_assignment.this["Queue|receiver|unnamed"].principal_id == "00000000-0000-0000-0000-000000000003"
    )
    error_message = "Each queue role assignment must use the queue name as its scope key and target its own queue."
  }
}
