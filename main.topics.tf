resource "azurerm_servicebus_topic" "this" {
  for_each = var.sku != "Basic" ? var.topics : {}

  name                                    = each.key

  namespace_id                            = azurerm_servicebus_namespace.this.id

  status                                  = each.value.status
  support_ordering                        = each.value.support_ordering
  default_message_ttl                     = each.value.default_message_ttl
  auto_delete_on_idle                     = each.value.auto_delete_on_idle 
  max_size_in_megabytes                   = each.value.max_size_in_megabytes
  enable_batched_operations               = each.value.enable_batched_operations
  requires_duplicate_detection            = each.value.requires_duplicate_detection
  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
  enable_express                          = var.sku != "Premium" ? each.value.enable_express : false 
  max_message_size_in_kilobytes           = var.sku != "Premium" ? null : coalesce(each.value.max_message_size_in_kilobytes, 1024)
  enable_partitioning                     = var.sku != "Premium" ? each.value.enable_partitioning : local.normalized_premium_messaging_partitions > 1

  lifecycle {
    precondition {
      condition = alltrue([
        for _, v in var.topics : 
        var.sku != "Premium" || v.max_message_size_in_kilobytes == null ? true : var.sku == "Premium" && v.max_message_size_in_kilobytes >= 1024 && v.max_message_size_in_kilobytes <= 102400
      ])
      error_message = "The max_message_size_in_kilobytes parameter if specified must be between 1024 and 102400 for Premium"
    }
  }
}

resource "azurerm_servicebus_topic_authorization_rule" "this" {
  for_each = local.topic_rules

  name     = each.value.rule_name

  topic_id = azurerm_servicebus_topic.this[each.value.topic_name].id

  manage = each.value.manage
  send   = each.value.manage ? true : each.value.send
  listen = each.value.manage ? true : each.value.listen
}