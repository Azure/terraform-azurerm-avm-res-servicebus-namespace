resource "azurerm_servicebus_topic" "this" {
  for_each = local.normalized_topics

  name                                    = each.key
  namespace_id                            = azurerm_servicebus_namespace.this.id
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  batched_operations_enabled              = each.value.enable_batched_operations
  default_message_ttl                     = each.value.default_message_ttl
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  express_enabled                         = var.sku == local.standard_sku_name ? each.value.enable_express : false
  max_message_size_in_kilobytes           = var.sku == local.premium_sku_name ? coalesce(each.value.max_message_size_in_kilobytes, local.smallest_premium_max_message_size_in_kilobytes) : null
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  partitioning_enabled                    = var.sku != local.premium_sku_name ? each.value.enable_partitioning : local.normalized_premium_messaging_partitions > 1
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  status                                  = each.value.status
  support_ordering                        = each.value.support_ordering

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

resource "azurerm_servicebus_topic_authorization_rule" "this" {
  for_each = local.topic_rules

  name     = each.value.rule_name
  topic_id = azurerm_servicebus_topic.this[each.value.topic_name].id
  listen   = each.value.rule_params.manage ? true : each.value.rule_params.listen
  manage   = each.value.rule_params.manage
  send     = each.value.rule_params.manage ? true : each.value.rule_params.send
}

resource "azurerm_servicebus_subscription" "base_topics" {
  for_each = local.base_topics

  max_delivery_count                        = each.value.subscription_params.max_delivery_count
  name                                      = each.value.subscription_name
  topic_id                                  = azurerm_servicebus_topic.this[each.value.topic_name].id
  auto_delete_on_idle                       = each.value.subscription_params.auto_delete_on_idle
  batched_operations_enabled                = each.value.subscription_params.enable_batched_operations
  dead_lettering_on_filter_evaluation_error = each.value.subscription_params.dead_lettering_on_filter_evaluation_error
  dead_lettering_on_message_expiration      = each.value.subscription_params.dead_lettering_on_message_expiration
  default_message_ttl                       = each.value.subscription_params.default_message_ttl
  forward_dead_lettered_messages_to         = each.value.subscription_params.forward_dead_lettered_messages_to
  forward_to                                = each.value.subscription_params.forward_to
  lock_duration                             = each.value.subscription_params.lock_duration
  requires_session                          = each.value.subscription_params.requires_session
  status                                    = each.value.subscription_params.status
}

resource "azurerm_servicebus_subscription" "forward_topics" {
  for_each = local.forward_topics

  max_delivery_count                        = each.value.subscription_params.max_delivery_count
  name                                      = each.value.subscription_name
  topic_id                                  = azurerm_servicebus_topic.this[each.value.topic_name].id
  auto_delete_on_idle                       = each.value.subscription_params.auto_delete_on_idle
  batched_operations_enabled                = each.value.subscription_params.enable_batched_operations
  dead_lettering_on_filter_evaluation_error = each.value.subscription_params.dead_lettering_on_filter_evaluation_error
  dead_lettering_on_message_expiration      = each.value.subscription_params.dead_lettering_on_message_expiration
  default_message_ttl                       = each.value.subscription_params.default_message_ttl
  forward_dead_lettered_messages_to         = each.value.subscription_params.forward_dead_lettered_messages_to
  forward_to                                = each.value.subscription_params.forward_to
  lock_duration                             = each.value.subscription_params.lock_duration
  requires_session                          = each.value.subscription_params.requires_session
  status                                    = each.value.subscription_params.status

  depends_on = [azurerm_servicebus_subscription.base_topics, azurerm_servicebus_queue.base_queues]
}
