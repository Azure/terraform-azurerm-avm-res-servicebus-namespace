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
    for_each = var.sku == "Premium" && var.customer_managed_key != null ? [1] : []

    content {
      infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
      identity_id                       = var.customer_managed_key.user_assigned_identity.resource_id
      key_vault_key_id                  = "https://${local.customer_managed_key_keyvault_name}.vault.azure.net/keys/${var.customer_managed_key.key_name}/${var.customer_managed_key.key_version != null ? var.customer_managed_key.key_version : ""}"
    }
  }

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" ? [1] : []

    content {
      public_network_access_enabled = var.public_network_access_enabled
      default_action                = var.network_rule_config.default_action
      ip_rules                      = var.network_rule_config.cidr_or_ip_rules
      trusted_services_allowed      = var.network_rule_config.trusted_services_allowed

      dynamic "network_rules" {
        for_each = var.network_rule_config.network_rules

        content {
          subnet_id = network_rules.value.subnet_id
        }
      }
    }
  }

  # These cases are handled in the normalized_xxx variables. Serves as unit testing in case of future changes to those variables
  lifecycle {
    precondition {
      condition     = var.sku != "Premium" ? local.normalized_zone_redundant == false : true
      error_message = "Zone redundant requires Premium SKU"
    }

    precondition {
      condition     = var.sku != "Premium" ? local.normalized_premium_messaging_partitions == 0 : true
      error_message = "Premium messaging partitions requires Premium SKU"
    }

    precondition {
      condition     = var.sku != "Premium" ? local.normalized_capacity == 0 : true
      error_message = "Capacity parameter requires Premium SKU"
    }
  }
}

resource "azurerm_servicebus_namespace_authorization_rule" "this" {
  for_each = var.authorization_rules

  name = each.key

  namespace_id = azurerm_servicebus_namespace.this.id

  manage = each.value.manage
  send   = each.value.manage ? true : each.value.send
  listen = each.value.manage ? true : each.value.listen
}

# Commented as it is currently bugged. https://github.com/hashicorp/terraform-provider-azurerm/issues/22287
# resource "azurerm_servicebus_namespace_disaster_recovery_config" "this" {
#   count = var.sku == "Premium" && var.disaster_recovery_config != null ? 1 : 0

#   primary_namespace_id        = azurerm_servicebus_namespace.this.id
#   name                        = var.disaster_recovery_config.dns_alias_name
#   partner_namespace_id        = var.disaster_recovery_config.partner_namespace_id
#   alias_authorization_rule_id = var.disaster_recovery_config.alias_authorization_rule_id
# }