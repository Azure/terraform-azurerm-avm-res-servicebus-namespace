resource "azurerm_servicebus_namespace" "this" {
  name = var.name

  sku                           = var.sku
  tags                          = var.tags
  location                      = var.location
  local_auth_enabled            = var.local_auth_enabled
  resource_group_name           = var.resource_group_name
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  capacity                     = local.normalized_capacity
  zone_redundant               = local.normalized_zone_redundant
  premium_messaging_partitions = local.normalized_premium_messaging_partitions

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.sku == local.premium_sku_name && var.customer_managed_key != null ? [1] : []

    content {
      key_vault_key_id                  = local.normalized_cmk_key_url
      infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
      identity_id                       = var.customer_managed_key.user_assigned_identity.resource_id
    }
  }

  dynamic "network_rule_set" {
    for_each = var.sku == local.premium_sku_name ? [1] : []

    content {
      public_network_access_enabled = var.public_network_access_enabled
      default_action                = var.network_rule_config.default_action
      ip_rules                      = var.network_rule_config.cidr_or_ip_rules
      trusted_services_allowed      = var.network_rule_config.trusted_services_allowed

      dynamic "network_rules" {
        for_each = var.network_rule_config.network_rules

        content {
          subnet_id                            = network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = false
        }
      }
    }
  }

  # These cases are handled in the normalized_xxx variables. Serves as unit testing in case of future changes to those variables
  lifecycle {
    precondition {
      condition     = var.sku != local.premium_sku_name ? local.normalized_zone_redundant == false : true
      error_message = "Zone redundant requires Premium SKU"
    }

    precondition {
      condition     = var.sku != local.premium_sku_name ? local.normalized_premium_messaging_partitions == 0 : true
      error_message = "Premium messaging partitions requires Premium SKU"
    }

    precondition {
      condition     = var.sku != local.premium_sku_name ? local.normalized_capacity == 0 : true
      error_message = "Capacity parameter requires Premium SKU"
    }
  }
}

resource "azurerm_servicebus_namespace_authorization_rule" "this" {
  for_each = var.authorization_rules

  name = coalesce(each.value.name, each.key)

  namespace_id = azurerm_servicebus_namespace.this.id

  manage = each.value.manage
  send   = each.value.manage ? true : each.value.send
  listen = each.value.manage ? true : each.value.listen
}
