locals {
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }

  normalized_capacity = var.sku != "Premium" ? 0 : coalesce(var.capacity, 1)

  normalized_zone_redundant = var.sku != "Premium" ? false : coalesce(var.zone_redundant, true)

  normalized_premium_messaging_partitions = var.sku != "Premium" ? 0 : coalesce(var.premium_messaging_partitions, 1)

  customer_managed_key_keyvault_name = var.customer_managed_key != null ? element(split("/", var.customer_managed_key.key_vault_resource_id), 8) : null
}
