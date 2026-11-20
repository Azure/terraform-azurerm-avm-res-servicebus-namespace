resource "azapi_resource" "lock" {
  for_each = local.total_locks

  name = coalesce(each.value.lock.name, "lock-${each.value.lock.kind}")
  parent_id = (
    each.value.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_name].id :
    each.value.scope_type == local.private_endpoint_scope_type ? azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_name].id :
    azurerm_servicebus_namespace.this.id
  )
  type = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = each.value.lock.kind
      notes = coalesce(try(each.value.lock.notes, null), each.value.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources.")
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

  # Create the locks last and remove them first. A ReadOnly lock blocks changes to the child resources.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzureRM provider waited for the lock
# to be gone before it continued. This pause does the same: it is destroyed after the locks and before
# the resources they protect.
resource "time_sleep" "lock_removal" {
  count = length(local.total_locks) > 0 ? 1 : 0

  destroy_duration = "30s"

  depends_on = [
    azurerm_servicebus_namespace.this,
    azurerm_servicebus_namespace_authorization_rule.this,
    azurerm_servicebus_queue.base_queues, azurerm_servicebus_queue.forward_queues, azurerm_servicebus_queue_authorization_rule.this,
    azurerm_servicebus_topic.this, azurerm_servicebus_topic_authorization_rule.this, azurerm_servicebus_subscription.base_topics, azurerm_servicebus_subscription.forward_topics,

    azapi_resource.diagnostic_settings, azapi_resource.role_assignments,
    azurerm_private_endpoint_application_security_group_association.this,
    azurerm_private_endpoint.this_managed_dns_zone_groups, azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  ]
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}
