resource "azurerm_servicebus_queue" "base_queues" {
  for_each = local.base_queues

  name                                    = each.key
  namespace_id                            = azurerm_servicebus_namespace.this.id
  auto_delete_on_idle                     = var.sku != local.basic_sku_name ? each.value.auto_delete_on_idle : null
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  default_message_ttl                     = each.value.default_message_ttl
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_batched_operations               = each.value.enable_batched_operations
  enable_express                          = var.sku == local.standard_sku_name ? each.value.enable_express : null
  enable_partitioning                     = var.sku != local.premium_sku_name ? each.value.enable_partitioning : local.normalized_premium_messaging_partitions > 1
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  forward_to                              = var.sku != local.basic_sku_name ? each.value.forward_to : null
  lock_duration                           = each.value.lock_duration
  max_delivery_count                      = each.value.max_delivery_count
  max_message_size_in_kilobytes           = var.sku == local.premium_sku_name ? coalesce(each.value.max_message_size_in_kilobytes, local.smallest_premium_max_message_size_in_kilobytes) : null
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  requires_duplicate_detection            = var.sku != local.basic_sku_name ? each.value.requires_duplicate_detection : null
  requires_session                        = var.sku != local.basic_sku_name ? each.value.requires_session : null
  status                                  = each.value.status

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

resource "azurerm_servicebus_queue" "forward_queues" {
  for_each = local.forward_queues

  name                                    = each.key
  namespace_id                            = azurerm_servicebus_namespace.this.id
  auto_delete_on_idle                     = var.sku != local.basic_sku_name ? each.value.auto_delete_on_idle : null
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  default_message_ttl                     = each.value.default_message_ttl
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_batched_operations               = each.value.enable_batched_operations
  enable_express                          = var.sku == local.standard_sku_name ? each.value.enable_express : null
  enable_partitioning                     = var.sku != local.premium_sku_name ? each.value.enable_partitioning : local.normalized_premium_messaging_partitions > 1
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  forward_to                              = var.sku != local.basic_sku_name ? each.value.forward_to : null
  lock_duration                           = each.value.lock_duration
  max_delivery_count                      = each.value.max_delivery_count
  max_message_size_in_kilobytes           = var.sku == local.premium_sku_name ? coalesce(each.value.max_message_size_in_kilobytes, local.smallest_premium_max_message_size_in_kilobytes) : null
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  requires_duplicate_detection            = var.sku != local.basic_sku_name ? each.value.requires_duplicate_detection : null
  requires_session                        = var.sku != local.basic_sku_name ? each.value.requires_session : null
  status                                  = each.value.status

  depends_on = [azurerm_servicebus_queue.base_queues]

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

resource "azurerm_servicebus_queue_authorization_rule" "this" {
  for_each = local.queue_rules

  name     = each.value.rule_name
  queue_id = try(azurerm_servicebus_queue.base_queues[each.value.queue_name].id, azurerm_servicebus_queue.forward_queues[each.value.queue_name].id)
  listen   = each.value.rule_params.manage ? true : each.value.rule_params.listen
  manage   = each.value.rule_params.manage
  send     = each.value.rule_params.manage ? true : each.value.rule_params.send
}