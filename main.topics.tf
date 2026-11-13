locals {
  # The AzureRM provider sent this value, which means never and unbounded, for an unset auto-delete or
  # message time to live on topics and subscriptions.
  never_timespan = "P10675199DT2H48M5.4775807S"
  # The body of each subscription. It reproduces what the AzureRM provider sent.
  subscription_bodies = {
    for key, subscription in local.topic_subscriptions : key => {
      properties = {
        autoDeleteOnIdle                          = coalesce(subscription.subscription_params.auto_delete_on_idle, local.never_timespan)
        deadLetteringOnFilterEvaluationExceptions = subscription.subscription_params.dead_lettering_on_filter_evaluation_error
        deadLetteringOnMessageExpiration          = subscription.subscription_params.dead_lettering_on_message_expiration
        defaultMessageTimeToLive                  = coalesce(subscription.subscription_params.default_message_ttl, local.never_timespan)
        enableBatchedOperations                   = subscription.subscription_params.enable_batched_operations
        forwardDeadLetteredMessagesTo             = subscription.subscription_params.forward_dead_lettered_messages_to
        forwardTo                                 = subscription.subscription_params.forward_to
        lockDuration                              = subscription.subscription_params.lock_duration
        maxDeliveryCount                          = subscription.subscription_params.max_delivery_count
        requiresSession                           = subscription.subscription_params.requires_session
        status                                    = subscription.subscription_params.status
      }
    }
  }
  subscription_resources = merge(azapi_resource.base_topics, azapi_resource.forward_topics)
}

# The body reproduces what the AzureRM provider sent, including the defaults it filled in for unset
# inputs, so that upgrading moves the existing topics without changing them.
resource "azapi_resource" "topics" {
  for_each = local.normalized_topics

  name      = each.key
  parent_id = azapi_resource.this.id
  type      = "Microsoft.ServiceBus/namespaces/topics@2024-01-01"
  body = {
    properties = {
      autoDeleteOnIdle                    = coalesce(each.value.auto_delete_on_idle, local.never_timespan)
      defaultMessageTimeToLive            = coalesce(each.value.default_message_ttl, local.never_timespan)
      duplicateDetectionHistoryTimeWindow = each.value.duplicate_detection_history_time_window
      enableBatchedOperations             = each.value.enable_batched_operations
      enableExpress                       = var.sku == local.standard_sku_name ? coalesce(each.value.enable_express, false) : false
      enablePartitioning                  = var.sku != local.premium_sku_name ? coalesce(each.value.enable_partitioning, false) : local.normalized_premium_messaging_partitions > 1
      maxMessageSizeInKilobytes           = var.sku == local.premium_sku_name ? coalesce(each.value.max_message_size_in_kilobytes, local.smallest_premium_max_message_size_in_kilobytes) : null
      maxSizeInMegabytes                  = each.value.max_size_in_megabytes
      requiresDuplicateDetection          = each.value.requires_duplicate_detection
      status                              = each.value.status
      supportOrdering                     = each.value.support_ordering
    }
  }
  # Azure reports sixteen times the configured size for a partitioned topic outside Premium, which the
  # AzureRM provider corrected when it read the topic. Those topics ignore later size differences.
  ignore_body_changes    = var.sku != local.premium_sku_name && coalesce(each.value.enable_partitioning, false) ? ["properties.maxSizeInMegabytes"] : null
  ignore_null_property   = true
  response_export_values = ["properties.maxMessageSizeInKilobytes"]

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    precondition {
      condition     = var.sku != local.premium_sku_name || each.value.max_message_size_in_kilobytes == null ? true : var.sku == local.premium_sku_name && each.value.max_message_size_in_kilobytes >= local.smallest_premium_max_message_size_in_kilobytes && each.value.max_message_size_in_kilobytes <= local.biggest_premium_max_message_size_in_kilobytes
      error_message = "The max_message_size_in_kilobytes parameter if specified must be between ${local.smallest_premium_max_message_size_in_kilobytes} and ${local.biggest_premium_max_message_size_in_kilobytes} for Premium"
    }
    precondition {
      condition     = var.sku == local.standard_sku_name && coalesce(each.value.enable_express, false) && coalesce(each.value.requires_duplicate_detection, false) ? false : true
      error_message = "The requires_duplicate_detection parameter must be false when enable_express is true for Standard"
    }
  }
}

moved {
  from = azurerm_servicebus_topic.this
  to   = azapi_resource.topics
}

resource "azapi_resource" "topic_authorization_rules" {
  for_each = local.topic_rules

  name      = each.value.rule_name
  parent_id = azapi_resource.topics[each.value.topic_name].id
  type      = "Microsoft.ServiceBus/namespaces/topics/authorizationRules@2024-01-01"
  body = {
    properties = {
      # The same order the AzureRM provider sent.
      rights = concat(
        each.value.rule_params.manage || each.value.rule_params.listen ? ["Listen"] : [],
        each.value.rule_params.manage || each.value.rule_params.send ? ["Send"] : [],
        each.value.rule_params.manage ? ["Manage"] : [],
      )
    }
  }
  response_export_values = []

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_servicebus_topic_authorization_rule.this
  to   = azapi_resource.topic_authorization_rules
}

data "azapi_resource_action" "topic_authorization_rule_keys" {
  for_each = azapi_resource.topic_authorization_rules

  action                           = "listKeys"
  method                           = "POST"
  resource_id                      = each.value.id
  type                             = "Microsoft.ServiceBus/namespaces/topics/authorizationRules@2024-01-01"
  sensitive_response_export_values = ["aliasPrimaryConnectionString", "aliasSecondaryConnectionString", "primaryConnectionString", "primaryKey", "secondaryConnectionString", "secondaryKey"]
}

resource "azapi_resource" "base_topics" {
  for_each = local.base_topics

  name                   = each.value.subscription_name
  parent_id              = azapi_resource.topics[each.value.topic_name].id
  type                   = "Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01"
  body                   = local.subscription_bodies[each.key]
  ignore_null_property   = true
  response_export_values = []

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_servicebus_subscription.base_topics
  to   = azapi_resource.base_topics
}

# Subscriptions that forward to queues or topics are created after the entities they can forward to.
resource "azapi_resource" "forward_topics" {
  for_each = local.forward_topics

  name                   = each.value.subscription_name
  parent_id              = azapi_resource.topics[each.value.topic_name].id
  type                   = "Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01"
  body                   = local.subscription_bodies[each.key]
  ignore_null_property   = true
  response_export_values = []

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [azapi_resource.base_topics, azapi_resource.base_queues]
}

moved {
  from = azurerm_servicebus_subscription.forward_topics
  to   = azapi_resource.forward_topics
}
