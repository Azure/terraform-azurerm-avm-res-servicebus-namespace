resource "azurerm_servicebus_queue" "this" {
  for_each = var.queues

  name                                    = each.key

  namespace_id                            = azurerm_servicebus_namespace.this.id

  status                                  = each.value.status
  forward_to                              = each.value.forward_to
  lock_duration                           = each.value.lock_duration
  requires_session                        = each.value.requires_session
  max_delivery_count                      = each.value.max_delivery_count
  default_message_ttl                     = each.value.default_message_ttl
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  enable_batched_operations               = each.value.enable_batched_operations
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_express                          = var.sku == "Premium" ? false : each.value.enable_express
  enable_partitioning                     = local.normalized_premium_messaging_partitions > 1 && var.sku == "Premium" ? true : each.value.enable_partitioning
  max_message_size_in_kilobytes           = var.sku != "Premium" ? null : each.value.max_message_size_in_kilobytes == null && var.sku == "Premium" ? 1024 : each.value.max_message_size_in_kilobytes

  lifecycle {
    precondition {
      condition = alltrue([
        for _, v in var.queues : 
        var.sku != "Premium" || v.max_message_size_in_kilobytes == null ? true : var.sku == "Premium" && v.max_message_size_in_kilobytes >= 1024 && v.max_message_size_in_kilobytes <= 102400
      ])
      error_message = "The max_message_size_in_kilobytes parameter if specified must be between 1024 and 102400 for Premium"
    }
  }
}

resource "azurerm_servicebus_queue_authorization_rule" "this" {
  for_each = local.queue_rules

  name     = each.value.rule_name

  queue_id = azurerm_servicebus_queue.this[each.value.queue_name].id

  manage = each.value.manage
  send   = each.value.manage ? true : each.value.send
  listen = each.value.manage ? true : each.value.listen
}