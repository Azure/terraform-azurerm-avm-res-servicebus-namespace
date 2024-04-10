resource "azurerm_servicebus_queue" "base_queues" {
  for_each = { for k, v in var.queues : k => v if v.forward_to == null && v.forward_dead_lettered_messages_to == null }

  name = each.key

  namespace_id = azurerm_servicebus_namespace.this.id

  status                                  = each.value.status
  lock_duration                           = each.value.lock_duration
  max_delivery_count                      = each.value.max_delivery_count
  default_message_ttl                     = each.value.default_message_ttl
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  enable_batched_operations               = each.value.enable_batched_operations
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  forward_to                              = var.sku != "Basic" ? each.value.forward_to : null
  requires_session                        = var.sku != "Basic" ? each.value.requires_session : null
  enable_express                          = var.sku == "Standard" ? each.value.enable_express : null
  auto_delete_on_idle                     = var.sku != "Basic" ? each.value.auto_delete_on_idle : null
  requires_duplicate_detection            = var.sku != "Basic" ? each.value.requires_duplicate_detection : null
  max_message_size_in_kilobytes           = var.sku == "Premium" ? coalesce(each.value.max_message_size_in_kilobytes, 1024) : null
  enable_partitioning                     = var.sku != "Premium" ? each.value.enable_partitioning : local.normalized_premium_messaging_partitions > 1

  lifecycle {
    precondition {
      condition     = var.sku != "Premium" || each.value.max_message_size_in_kilobytes == null ? true : var.sku == "Premium" && each.value.max_message_size_in_kilobytes >= 1024 && each.value.max_message_size_in_kilobytes <= 102400
      error_message = "The max_message_size_in_kilobytes parameter if specified must be between 1024 and 102400 for Premium"
    }

    precondition {
      condition     = var.sku == "Standard" && coalesce(each.value.enable_express, false) && coalesce(each.value.requires_duplicate_detection, false) ? false : true
      error_message = "The requires_duplicate_detection parameter must be false when enable_express is true for Standard"
    }
  }

  # depends_on = [ azurerm_servicebus_namespace_disaster_recovery_config.this ]
}

resource "azurerm_servicebus_queue" "forward_queues" {
  for_each = { for k, v in var.queues : k => v if v.forward_to != null || v.forward_dead_lettered_messages_to != null }

  name = each.key

  namespace_id = azurerm_servicebus_namespace.this.id

  status                                  = each.value.status
  lock_duration                           = each.value.lock_duration
  max_delivery_count                      = each.value.max_delivery_count
  default_message_ttl                     = each.value.default_message_ttl
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  enable_batched_operations               = each.value.enable_batched_operations
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  forward_to                              = var.sku != "Basic" ? each.value.forward_to : null
  requires_session                        = var.sku != "Basic" ? each.value.requires_session : null
  enable_express                          = var.sku == "Standard" ? each.value.enable_express : null
  auto_delete_on_idle                     = var.sku != "Basic" ? each.value.auto_delete_on_idle : null
  requires_duplicate_detection            = var.sku != "Basic" ? each.value.requires_duplicate_detection : null
  max_message_size_in_kilobytes           = var.sku == "Premium" ? coalesce(each.value.max_message_size_in_kilobytes, 1024) : null
  enable_partitioning                     = var.sku != "Premium" ? each.value.enable_partitioning : local.normalized_premium_messaging_partitions > 1

  lifecycle {
    precondition {
      condition     = var.sku != "Premium" || each.value.max_message_size_in_kilobytes == null ? true : var.sku == "Premium" && each.value.max_message_size_in_kilobytes >= 1024 && each.value.max_message_size_in_kilobytes <= 102400
      error_message = "The max_message_size_in_kilobytes parameter if specified must be between 1024 and 102400 for Premium"
    }

    precondition {
      condition     = var.sku == "Standard" && coalesce(each.value.enable_express, false) && coalesce(each.value.requires_duplicate_detection, false) ? false : true
      error_message = "The requires_duplicate_detection parameter must be false when enable_express is true for Standard"
    }
  }

  depends_on = [azurerm_servicebus_queue.base_queues]
}

resource "azurerm_servicebus_queue_authorization_rule" "this" {
  for_each = local.queue_rules

  name = each.value.rule_name

  queue_id = try(azurerm_servicebus_queue.base_queues[each.value.queue_name].id, azurerm_servicebus_queue.forward_queues[each.value.queue_name].id)

  manage = each.value.rule_params.manage
  send   = each.value.rule_params.manage ? true : each.value.rule_params.send
  listen = each.value.rule_params.manage ? true : each.value.rule_params.listen
}