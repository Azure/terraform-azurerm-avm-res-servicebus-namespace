resource "azurerm_servicebus_queue" "this" {
  for_each = var.queues

  name                                    = each.key

  namespace_id                            = azurerm_servicebus_namespace.this.id

  status                                  = each.value.status
  forward_to                              = each.value.forward_to
  lock_duration                           = each.value.lock_duration
  enable_express                          = each.value.enable_express
  requires_session                        = each.value.requires_session
  enable_partitioning                     = each.value.enable_partitioning
  max_delivery_count                      = each.value.max_delivery_count
  default_message_ttl                     = each.value.default_message_ttl
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  enable_batched_operations               = each.value.enable_batched_operations
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  max_message_size_in_kilobytes           = each.value.max_message_size_in_kilobytes
  forward_dead_lettered_messages_to       = each.value.forward_dead_lettered_messages_to
  dead_lettering_on_message_expiration    = each.value.dead_lettering_on_message_expiration
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
}

resource "azurerm_servicebus_queue_authorization_rule" "this" {
  for_each = local.queue_rules

  name     = each.value.rule_name

  queue_id = azurerm_servicebus_queue.this[each.value.queue_name].id

  send   = each.value.send
  listen = each.value.listen
  manage = each.value.manage
}