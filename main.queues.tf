locals {
  # The body of each queue. It reproduces what the AzureRM provider sent, including the defaults it
  # filled in for unset inputs, so that upgrading moves the existing queues without changing them.
  queue_bodies = {
    for name, queue in local.normalized_queues : name => {
      properties = {
        autoDeleteOnIdle                    = var.sku != local.basic_sku_name ? queue.auto_delete_on_idle : null
        deadLetteringOnMessageExpiration    = queue.dead_lettering_on_message_expiration
        defaultMessageTimeToLive            = queue.default_message_ttl
        duplicateDetectionHistoryTimeWindow = queue.duplicate_detection_history_time_window
        enableBatchedOperations             = queue.enable_batched_operations
        enableExpress                       = var.sku == local.standard_sku_name ? coalesce(queue.enable_express, false) : false
        enablePartitioning                  = var.sku != local.premium_sku_name ? coalesce(queue.enable_partitioning, false) : local.normalized_premium_messaging_partitions > 1
        forwardDeadLetteredMessagesTo       = queue.forward_dead_lettered_messages_to
        forwardTo                           = var.sku != local.basic_sku_name ? queue.forward_to : null
        lockDuration                        = queue.lock_duration
        maxDeliveryCount                    = queue.max_delivery_count
        maxMessageSizeInKilobytes           = var.sku == local.premium_sku_name ? coalesce(queue.max_message_size_in_kilobytes, local.smallest_premium_max_message_size_in_kilobytes) : null
        maxSizeInMegabytes                  = queue.max_size_in_megabytes
        requiresDuplicateDetection          = var.sku != local.basic_sku_name ? queue.requires_duplicate_detection : false
        requiresSession                     = var.sku != local.basic_sku_name ? queue.requires_session : false
        status                              = queue.status
      }
    }
  }
  # Azure reports sixteen times the configured size for a partitioned queue outside Premium, which the
  # AzureRM provider corrected when it read the queue. Those queues ignore later size differences.
  queue_ignore_body_changes = {
    for name, body in local.queue_bodies : name => var.sku != local.premium_sku_name && body.properties.enablePartitioning ? ["properties.maxSizeInMegabytes"] : null
  }
  queue_resources = merge(azapi_resource.base_queues, azapi_resource.forward_queues)
}

resource "azapi_resource" "base_queues" {
  for_each = local.base_queues

  name                   = each.key
  parent_id              = azapi_resource.this.id
  type                   = "Microsoft.ServiceBus/namespaces/queues@2024-01-01"
  body                   = local.queue_bodies[each.key]
  ignore_body_changes    = local.queue_ignore_body_changes[each.key]
  ignore_null_property   = true
  response_export_values = ["properties.autoDeleteOnIdle", "properties.defaultMessageTimeToLive", "properties.maxMessageSizeInKilobytes"]

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
  from = azurerm_servicebus_queue.base_queues
  to   = azapi_resource.base_queues
}

# Queues that forward to other queues or topics are created after the queues they can forward to.
resource "azapi_resource" "forward_queues" {
  for_each = local.forward_queues

  name                   = each.key
  parent_id              = azapi_resource.this.id
  type                   = "Microsoft.ServiceBus/namespaces/queues@2024-01-01"
  body                   = local.queue_bodies[each.key]
  ignore_body_changes    = local.queue_ignore_body_changes[each.key]
  ignore_null_property   = true
  response_export_values = ["properties.autoDeleteOnIdle", "properties.defaultMessageTimeToLive", "properties.maxMessageSizeInKilobytes"]

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
  depends_on = [azapi_resource.base_queues]
}

moved {
  from = azurerm_servicebus_queue.forward_queues
  to   = azapi_resource.forward_queues
}

resource "azapi_resource" "queue_authorization_rules" {
  for_each = local.queue_rules

  name      = each.value.rule_name
  parent_id = local.queue_resources[each.value.queue_name].id
  type      = "Microsoft.ServiceBus/namespaces/queues/authorizationRules@2024-01-01"
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
  from = azurerm_servicebus_queue_authorization_rule.this
  to   = azapi_resource.queue_authorization_rules
}

data "azapi_resource_action" "queue_authorization_rule_keys" {
  for_each = azapi_resource.queue_authorization_rules

  action                           = "listKeys"
  method                           = "POST"
  resource_id                      = each.value.id
  type                             = "Microsoft.ServiceBus/namespaces/queues/authorizationRules@2024-01-01"
  sensitive_response_export_values = ["aliasPrimaryConnectionString", "aliasSecondaryConnectionString", "primaryConnectionString", "primaryKey", "secondaryConnectionString", "secondaryKey"]
}
