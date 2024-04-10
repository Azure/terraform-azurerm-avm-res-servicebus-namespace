resource "azurerm_servicebus_topic" "this" {
  for_each = local.normalized_topics

  name = each.key

  namespace_id = azurerm_servicebus_namespace.this.id

  status                                  = each.value.status
  support_ordering                        = each.value.support_ordering
  default_message_ttl                     = each.value.default_message_ttl
  auto_delete_on_idle                     = each.value.auto_delete_on_idle
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  enable_batched_operations               = each.value.enable_batched_operations
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_express                          = var.sku == "Standard" ? each.value.enable_express : false
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

resource "azurerm_servicebus_topic_authorization_rule" "this" {
  for_each = local.topic_rules

  name = each.value.rule_name

  topic_id = azurerm_servicebus_topic.this[each.value.topic_name].id

  manage = each.value.rule_params.manage
  send   = each.value.rule_params.manage ? true : each.value.rule_params.send
  listen = each.value.rule_params.manage ? true : each.value.rule_params.listen
}

resource "azurerm_servicebus_subscription" "base_topics" {
  for_each = { for k, v in local.topic_subscriptions : k => v if v.subscription_params.forward_to == null && v.subscription_params.forward_dead_lettered_messages_to == null }

  name = each.value.subscription_name

  topic_id = azurerm_servicebus_topic.this[each.value.topic_name].id

  status                                    = each.value.subscription_params.status
  forward_to                                = each.value.subscription_params.forward_to
  lock_duration                             = each.value.subscription_params.lock_duration
  requires_session                          = each.value.subscription_params.requires_session
  max_delivery_count                        = each.value.subscription_params.max_delivery_count
  auto_delete_on_idle                       = each.value.subscription_params.auto_delete_on_idle
  default_message_ttl                       = each.value.subscription_params.default_message_ttl
  enable_batched_operations                 = each.value.subscription_params.enable_batched_operations
  forward_dead_lettered_messages_to         = each.value.subscription_params.forward_dead_lettered_messages_to
  dead_lettering_on_message_expiration      = each.value.subscription_params.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.subscription_params.dead_lettering_on_filter_evaluation_error
}

resource "azurerm_servicebus_subscription" "forward_topics" {
  for_each = { for k, v in local.topic_subscriptions : k => v if v.subscription_params.forward_to != null || v.subscription_params.forward_dead_lettered_messages_to != null }

  name = each.value.subscription_name

  topic_id = azurerm_servicebus_topic.this[each.value.topic_name].id

  status                                    = each.value.subscription_params.status
  forward_to                                = each.value.subscription_params.forward_to
  lock_duration                             = each.value.subscription_params.lock_duration
  requires_session                          = each.value.subscription_params.requires_session
  max_delivery_count                        = each.value.subscription_params.max_delivery_count
  auto_delete_on_idle                       = each.value.subscription_params.auto_delete_on_idle
  default_message_ttl                       = each.value.subscription_params.default_message_ttl
  enable_batched_operations                 = each.value.subscription_params.enable_batched_operations
  forward_dead_lettered_messages_to         = each.value.subscription_params.forward_dead_lettered_messages_to
  dead_lettering_on_message_expiration      = each.value.subscription_params.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = each.value.subscription_params.dead_lettering_on_filter_evaluation_error

  depends_on = [azurerm_servicebus_subscription.base_topics, azurerm_servicebus_queue.base_queues]
}