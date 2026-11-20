override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
  }
}

override_resource {
  target = azapi_resource.base_queues
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/target"
  }
}

override_resource {
  target = azapi_resource.forward_queues
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/source"
  }
}

override_resource {
  target = azapi_resource.topics
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/events"
  }
}

override_resource {
  target = azapi_resource.queue_authorization_rules
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/target/authorizationRules/sender"
  }
}

override_resource {
  target = azapi_resource.topic_authorization_rules
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/events/authorizationRules/manager"
  }
}

override_data {
  target = data.azapi_resource_action.queue_authorization_rule_keys
  values = {
    sensitive_output = {
      primaryKey = "queue-primary"
    }
  }
}

override_data {
  target = data.azapi_resource_action.topic_authorization_rule_keys
  values = {
    sensitive_output = {
      primaryKey = "topic-primary"
    }
  }
}

override_data {
  target = data.azapi_resource_action.default_keys
  values = {
    sensitive_output = {}
  }
}

mock_provider "azurerm" {}

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

variables {
  enable_telemetry    = false
  name                = "test-namespace"
  location            = "westeurope"
  resource_group_name = "test"
}

run "standard_queues_send_the_azurerm_defaults" {
  command = apply

  variables {
    sku = "Standard"
    queues = {
      target = {
        authorization_rules = {
          sender = {
            send = true
          }
        }
      }
      source = {
        forward_to          = "target"
        enable_partitioning = true
      }
    }
  }

  assert {
    condition = jsonencode(azapi_resource.base_queues["target"].body.properties) == jsonencode({
      autoDeleteOnIdle                    = null
      deadLetteringOnMessageExpiration    = false
      defaultMessageTimeToLive            = null
      duplicateDetectionHistoryTimeWindow = "PT10M"
      enableBatchedOperations             = true
      enableExpress                       = false
      enablePartitioning                  = false
      forwardDeadLetteredMessagesTo       = null
      forwardTo                           = null
      lockDuration                        = "PT1M"
      maxDeliveryCount                    = 10
      maxMessageSizeInKilobytes           = null
      maxSizeInMegabytes                  = 1024
      requiresDuplicateDetection          = false
      requiresSession                     = false
      status                              = "Active"
    })
    error_message = "A Standard queue MUST send the values the azurerm provider sent, with false for unset express and partitioning."
  }

  assert {
    condition     = length(azapi_resource.forward_queues) == 1 && azapi_resource.forward_queues["source"].body.properties.forwardTo == "target"
    error_message = "A forwarding queue MUST be created by the forward_queues resource."
  }

  assert {
    condition     = azapi_resource.queue_authorization_rules["target|sender"].body.properties.rights == tolist(["Send"]) && azapi_resource.queue_authorization_rules["target|sender"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/target"
    error_message = "A queue rule MUST be created on its queue with the configured rights."
  }

  assert {
    condition     = output.resource_queues["target"].namespace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace" && output.resource_queues["source"].forward_to == "target" && output.resource_queues["source"].partitioning_enabled
    error_message = "resource_queues MUST keep the azurerm attribute names for base and forwarding queues."
  }

  assert {
    condition     = nonsensitive(output.resource_queues_authorization_rules["target|sender"].primary_key) == "queue-primary" && output.resource_queues_authorization_rules["target|sender"].send && !output.resource_queues_authorization_rules["target|sender"].listen
    error_message = "resource_queues_authorization_rules MUST keep the azurerm flags and keys."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "premium_queue_defaults_the_message_size" {
  command = apply

  variables {
    sku = "Premium"
    queues = {
      target = {}
    }
  }

  assert {
    condition     = azapi_resource.base_queues["target"].body.properties.maxMessageSizeInKilobytes == 1024 && azapi_resource.base_queues["target"].body.properties.enablePartitioning == false && azapi_resource.base_queues["target"].body.properties.enableExpress == false
    error_message = "A Premium queue MUST default the message size and derive partitioning from the namespace."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "topics_and_subscriptions_send_never_for_unset_timespans" {
  command = apply

  variables {
    sku = "Standard"
    queues = {
      target = {}
    }
    topics = {
      events = {
        authorization_rules = {
          manager = {
            manage = true
          }
        }
        subscriptions = {
          plain = {}
          forwarding = {
            forward_to = "target"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.topics["events"].body.properties.autoDeleteOnIdle == "P10675199DT2H48M5.4775807S" && azapi_resource.topics["events"].body.properties.defaultMessageTimeToLive == "P10675199DT2H48M5.4775807S" && azapi_resource.topics["events"].body.properties.enableExpress == false
    error_message = "A topic MUST send never for unset auto-delete and time to live, as the azurerm provider did."
  }

  assert {
    condition = jsonencode(azapi_resource.base_topics["events|plain"].body.properties) == jsonencode({
      autoDeleteOnIdle                          = "P10675199DT2H48M5.4775807S"
      deadLetteringOnFilterEvaluationExceptions = true
      deadLetteringOnMessageExpiration          = false
      defaultMessageTimeToLive                  = "P10675199DT2H48M5.4775807S"
      enableBatchedOperations                   = true
      forwardDeadLetteredMessagesTo             = null
      forwardTo                                 = null
      lockDuration                              = "PT1M"
      maxDeliveryCount                          = 10
      requiresSession                           = false
      status                                    = "Active"
    })
    error_message = "A subscription MUST send the values the azurerm provider sent."
  }

  assert {
    condition     = length(azapi_resource.forward_topics) == 1 && azapi_resource.forward_topics["events|forwarding"].body.properties.forwardTo == "target" && azapi_resource.forward_topics["events|forwarding"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/events"
    error_message = "A forwarding subscription MUST be created by the forward_topics resource on its topic."
  }

  assert {
    condition     = azapi_resource.topic_authorization_rules["events|manager"].body.properties.rights == tolist(["Listen", "Send", "Manage"]) && nonsensitive(output.resource_topics_authorization_rules["events|manager"].primary_key) == "topic-primary"
    error_message = "A manage topic rule MUST send all rights and keep its keys in the output."
  }

  assert {
    condition     = output.resource_topics["events"].namespace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace" && output.resource_topics_subscriptions["events|forwarding"].forward_to == "target" && output.resource_topics_subscriptions["events|plain"].topic_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/events"
    error_message = "resource_topics and resource_topics_subscriptions MUST keep the azurerm attribute names."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "basic_creates_no_topics" {
  command = plan

  variables {
    sku = "Basic"
    topics = {
      events = {}
    }
  }

  assert {
    condition     = length(azapi_resource.topics) == 0
    error_message = "Basic namespaces MUST NOT create topics."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}
