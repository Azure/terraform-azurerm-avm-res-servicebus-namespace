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

  normalized_location  = var.location != null ? var.location : data.azurerm_resource_group.rg.location

  normalized_capacity = var.sku != "Premium" ? 0 : var.sku == "Premium" && var.capacity == null ? 1 : var.capacity

  normalized_premium_messaging_partitions = var.sku != "Premium" ? 0 : var.sku == "Premium" && var.capacity == null ? 1 : var.capacity

  normalized_zone_redundant = var.sku != "Premium" ? false : var.sku == "Premium" && var.zone_redundant == null ? true : var.zone_redundant

  customer_managed_key_keyvault_name = var.customer_managed_key != null ? element(split("/", var.customer_managed_key.key_vault_resource_id), 8) : null
}
