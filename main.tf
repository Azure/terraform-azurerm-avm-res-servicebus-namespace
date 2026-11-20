# The body reproduces what the AzureRM provider sent, so that upgrading moves the existing namespace
# without changing it.
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.ServiceBus/namespaces@2024-01-01"
  body = {
    sku = {
      # Azure reports no capacity for Basic and Standard, so it is sent only for Premium.
      capacity = var.sku == local.premium_sku_name ? local.normalized_capacity : null
      name     = var.sku
      tier     = var.sku
    }
    properties = {
      disableLocalAuth = !var.local_auth_enabled
      encryption = var.sku == local.premium_sku_name && var.customer_managed_key != null ? {
        keySource = "Microsoft.KeyVault"
        keyVaultProperties = [
          {
            identity = {
              userAssignedIdentity = var.customer_managed_key.user_assigned_identity.resource_id
            }
            keyName = var.customer_managed_key.key_name
            # The AzureRM provider sent the key vault's base URL, which ends with a slash.
            keyVaultUri = "https://${local.customer_managed_key_keyvault_name}.vault.azure.net/"
            keyVersion  = var.customer_managed_key.key_version
          }
        ]
        requireInfrastructureEncryption = var.infrastructure_encryption_enabled
      } : null
      minimumTlsVersion          = var.minimum_tls_version
      premiumMessagingPartitions = var.sku == local.premium_sku_name ? local.normalized_premium_messaging_partitions : null
      publicNetworkAccess        = var.public_network_access_enabled ? "Enabled" : "Disabled"
    }
  }
  ignore_null_property   = true
  response_export_values = ["properties.serviceBusEndpoint"]
  tags                   = var.tags

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # These cases are handled in the normalized_xxx variables. Serves as unit testing in case of future changes to those variables
  lifecycle {
    precondition {
      condition     = var.sku != local.premium_sku_name ? local.normalized_premium_messaging_partitions == 0 : true
      error_message = "Premium messaging partitions requires Premium SKU"
    }
    precondition {
      condition     = var.network_rule_config.default_action == "Deny" && length(var.network_rule_config.cidr_or_ip_rules) == 0 && (var.sku != local.premium_sku_name || length(var.network_rule_config.network_rules) == 0) ? false : true
      error_message = "The 'network_rule_config.default_action' can only be set to 'Allow' if no 'network_rule_config.cidr_or_ip_rules' are set and no 'network_rule_config.network_rules' are set for Premium"
    }
    precondition {
      condition     = var.sku != local.premium_sku_name ? local.normalized_capacity == 0 : true
      error_message = "Capacity parameter requires Premium SKU"
    }
  }
}

moved {
  from = azurerm_servicebus_namespace.this
  to   = azapi_resource.this
}

# Every namespace has a default network rule set, which the AzureRM provider wrote with a separate
# request after the namespace. It always exists, so it is updated in place rather than created: an
# `azapi_resource` would stop with "Resource already exists". Destroying this resource leaves the rule
# set as it is, and Azure removes it with the namespace.
resource "azapi_update_resource" "network_rule_set" {
  name      = "default"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.ServiceBus/namespaces/networkRuleSets@2024-01-01"
  body = {
    properties = {
      defaultAction = var.network_rule_config.default_action
      # Empty lists are sent rather than left out, because the body is merged into the existing rule
      # set and a missing list would keep the rules that are already there.
      ipRules = [
        for ip_rule in var.network_rule_config.cidr_or_ip_rules : {
          action = "Allow"
          ipMask = ip_rule
        }
      ]
      publicNetworkAccess         = var.public_network_access_enabled ? "Enabled" : "Disabled"
      trustedServiceAccessEnabled = var.network_rule_config.trusted_services_allowed
      virtualNetworkRules = [
        for network_rule in(var.sku == local.premium_sku_name ? var.network_rule_config.network_rules : []) : {
          ignoreMissingVnetServiceEndpoint = false
          subnet = {
            id = network_rule.subnet_id
          }
        }
      ]
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
}

# The AzureRM provider read the keys of the default rule into the namespace's attributes. They are read
# here only while SAS authentication is enabled, because Azure refuses the request otherwise.
data "azapi_resource_action" "default_keys" {
  count = var.local_auth_enabled ? 1 : 0

  action                           = "listKeys"
  method                           = "POST"
  resource_id                      = "${azapi_resource.this.id}/AuthorizationRules/RootManageSharedAccessKey"
  type                             = "Microsoft.ServiceBus/namespaces/AuthorizationRules@2024-01-01"
  sensitive_response_export_values = ["primaryConnectionString", "primaryKey", "secondaryConnectionString", "secondaryKey"]
}

resource "azapi_resource" "authorization_rules" {
  for_each = var.authorization_rules

  name      = coalesce(each.value.name, each.key)
  parent_id = azapi_resource.this.id
  type      = "Microsoft.ServiceBus/namespaces/AuthorizationRules@2024-01-01"
  body = {
    properties = {
      # The same order the AzureRM provider sent.
      rights = concat(
        each.value.manage || each.value.listen ? ["Listen"] : [],
        each.value.manage || each.value.send ? ["Send"] : [],
        each.value.manage ? ["Manage"] : [],
      )
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
}

moved {
  from = azurerm_servicebus_namespace_authorization_rule.this
  to   = azapi_resource.authorization_rules
}

data "azapi_resource_action" "authorization_rule_keys" {
  for_each = azapi_resource.authorization_rules

  action                           = "listKeys"
  method                           = "POST"
  resource_id                      = each.value.id
  type                             = "Microsoft.ServiceBus/namespaces/AuthorizationRules@2024-01-01"
  sensitive_response_export_values = ["aliasPrimaryConnectionString", "aliasSecondaryConnectionString", "primaryConnectionString", "primaryKey", "secondaryConnectionString", "secondaryKey"]
}
