resource "azurerm_management_lock" "this" {
  for_each = local.total_locks

  scope = (
    each.value.scope_type == "PrivateEndpoint" && var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_name].id :
    each.value.scope_type == "PrivateEndpoint" && var.private_endpoints_manage_dns_zone_group == false ? azurerm_private_endpoint.this_unmanaged_dns_zone_groups[each.value.pe_name].id :
    azurerm_servicebus_namespace.this.id
  )

  name = coalesce(each.value.lock.name, "lock-${each.value.lock.kind}")

  lock_level = each.value.lock.kind
  notes      = each.value.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
