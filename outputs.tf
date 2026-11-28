output "resource" {
  description = "The service bus namespace created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace.html#attributes-reference"
  sensitive   = true
  # The AzureRM attribute names are kept so that existing references keep working, including the keys
  # of the default authorization rule.
  value = {
    capacity = local.normalized_capacity
    customer_managed_key = var.sku == local.premium_sku_name && var.customer_managed_key != null ? [
      {
        identity_id                       = var.customer_managed_key.user_assigned_identity.resource_id
        infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
        key_vault_key_id                  = local.normalized_cmk_key_url
      }
    ] : []
    default_primary_connection_string   = try(data.azapi_resource_action.default_keys[0].sensitive_output.primaryConnectionString, null)
    default_primary_key                 = try(data.azapi_resource_action.default_keys[0].sensitive_output.primaryKey, null)
    default_secondary_connection_string = try(data.azapi_resource_action.default_keys[0].sensitive_output.secondaryConnectionString, null)
    default_secondary_key               = try(data.azapi_resource_action.default_keys[0].sensitive_output.secondaryKey, null)
    endpoint                            = try(azapi_resource.this.output.properties.serviceBusEndpoint, null)
    id                                  = azapi_resource.this.id
    identity = [
      for identity in azapi_resource.this.identity : {
        identity_ids = identity.identity_ids
        principal_id = identity.principal_id
        tenant_id    = identity.tenant_id
        type         = identity.type
      }
    ]
    local_auth_enabled  = var.local_auth_enabled
    location            = azapi_resource.this.location
    minimum_tls_version = var.minimum_tls_version
    name                = azapi_resource.this.name
    network_rule_set = [
      {
        default_action = var.network_rule_config.default_action
        ip_rules       = var.network_rule_config.cidr_or_ip_rules
        network_rules = [
          for network_rule in(var.sku == local.premium_sku_name ? var.network_rule_config.network_rules : []) : {
            ignore_missing_vnet_service_endpoint = false
            subnet_id                            = network_rule.subnet_id
          }
        ]
        public_network_access_enabled = var.public_network_access_enabled
        trusted_services_allowed      = var.network_rule_config.trusted_services_allowed
      }
    ]
    premium_messaging_partitions  = local.normalized_premium_messaging_partitions
    public_network_access_enabled = var.public_network_access_enabled
    resource_group_name           = var.resource_group_name
    sku                           = var.sku
    tags                          = azapi_resource.this.tags
  }
}

output "resource_authorization_rules" {
  description = "The service bus namespace authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule#attributes-reference"
  sensitive   = true
  # The AzureRM attribute names are kept so that existing references keep working, including the keys.
  value = {
    for key, rule in azapi_resource.authorization_rules : key => {
      id                                = rule.id
      listen                            = var.authorization_rules[key].manage ? true : var.authorization_rules[key].listen
      manage                            = var.authorization_rules[key].manage
      name                              = rule.name
      namespace_id                      = azapi_resource.this.id
      primary_connection_string         = try(data.azapi_resource_action.authorization_rule_keys[key].sensitive_output.primaryConnectionString, null)
      primary_connection_string_alias   = try(data.azapi_resource_action.authorization_rule_keys[key].sensitive_output.aliasPrimaryConnectionString, null)
      primary_key                       = try(data.azapi_resource_action.authorization_rule_keys[key].sensitive_output.primaryKey, null)
      secondary_connection_string       = try(data.azapi_resource_action.authorization_rule_keys[key].sensitive_output.secondaryConnectionString, null)
      secondary_connection_string_alias = try(data.azapi_resource_action.authorization_rule_keys[key].sensitive_output.aliasSecondaryConnectionString, null)
      secondary_key                     = try(data.azapi_resource_action.authorization_rule_keys[key].sensitive_output.secondaryKey, null)
      send                              = var.authorization_rules[key].manage ? true : var.authorization_rules[key].send
    }
  }
}

output "resource_diagnostic_settings" {
  description = "The diagnostic settings created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting#attributes-reference"
  # The AzureRM attribute names are kept so that existing references keep working.
  value = { for key, setting in azapi_resource.diagnostic_settings : key => {
    id                             = setting.id
    name                           = setting.name
    target_resource_id             = setting.parent_id
    eventhub_authorization_rule_id = setting.body.properties.eventHubAuthorizationRuleId
    eventhub_name                  = setting.body.properties.eventHubName
    log_analytics_destination_type = setting.body.properties.logAnalyticsDestinationType
    log_analytics_workspace_id     = setting.body.properties.workspaceId
    partner_solution_id            = setting.body.properties.marketplacePartnerId
    storage_account_id             = setting.body.properties.storageAccountId
  } }
}

output "resource_id" {
  description = "The resource ID of the service bus namespace created."
  value       = azapi_resource.this.id
}

output "resource_locks" {
  description = "The management locks created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock#attributes-reference"
  # The AzureRM attribute names are kept so that existing references keep working.
  value = { for key, lock in azapi_resource.lock : key => {
    id         = lock.id
    name       = lock.name
    scope      = lock.parent_id
    lock_level = lock.body.properties.level
    notes      = lock.body.properties.notes
  } }
}

output "resource_private_endpoints" {
  description = "A map of the private endpoints created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint#attributes-reference"
  # The AzureRM attribute names and shapes are kept so that references such as
  # `private_service_connection[0].private_ip_address` keep working.
  value = {
    for key, endpoint in local.private_endpoint_resources : key => {
      custom_dns_configs = [
        for config in try(endpoint.output.properties.customDnsConfigs, []) : {
          fqdn         = config.fqdn
          ip_addresses = config.ipAddresses
        }
      ]
      custom_network_interface_name = var.private_endpoints[key].network_interface_name
      id                            = endpoint.id
      ip_configuration = [
        for ip_configuration in values(var.private_endpoints[key].ip_configurations) : {
          member_name        = coalesce(ip_configuration.member_name, local.service_name)
          name               = ip_configuration.name
          private_ip_address = ip_configuration.private_ip_address
          subresource_name   = coalesce(var.private_endpoints[key].subresource_name, local.service_name)
        }
      ]
      location = endpoint.location
      name     = endpoint.name
      network_interface = [
        for nic in try(endpoint.output.properties.networkInterfaces, []) : {
          id   = nic.id
          name = provider::azapi::parse_resource_id("Microsoft.Network/networkInterfaces", nic.id).name
        }
      ]
      private_dns_zone_group = [
        for group in try([azapi_resource.private_dns_zone_groups[key]], []) : {
          id                   = group.id
          name                 = group.name
          private_dns_zone_ids = tolist(var.private_endpoints[key].private_dns_zone_resource_ids)
        }
      ]
      private_service_connection = [
        {
          is_manual_connection           = false
          name                           = local.private_endpoints[key].body.properties.privateLinkServiceConnections[0].name
          private_connection_resource_id = azapi_resource.this.id
          private_ip_address             = data.azapi_resource.private_endpoint_network_interfaces[key].output.private_ip_address
          subresource_names              = tolist(local.private_endpoints[key].body.properties.privateLinkServiceConnections[0].properties.groupIds)
        }
      ]
      resource_group_name = coalesce(var.private_endpoints[key].resource_group_name, var.resource_group_name)
      subnet_id           = var.private_endpoints[key].subnet_resource_id
      tags                = endpoint.tags
    }
  }
}

output "resource_private_endpoints_application_security_group_association" {
  description = "The private endpoint application security group associations created"
  # The application security groups are part of each private endpoint's body. The AzureRM attribute names
  # and ID format are kept so that existing references keep working.
  value = {
    for key, association in local.private_endpoint_application_security_group_associations : key => {
      application_security_group_id = association.asg_resource_id
      id                            = "${local.private_endpoint_resources[association.pe_key].id}|${association.asg_resource_id}"
      private_endpoint_id           = local.private_endpoint_resources[association.pe_key].id
    }
  }
}

output "resource_queues" {
  description = "The service bus queues created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association#attributes-reference"
  value       = merge(azurerm_servicebus_queue.base_queues, azurerm_servicebus_queue.forward_queues)
}

output "resource_queues_authorization_rules" {
  description = "The service bus queues authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue_authorization_rule#attributes-reference"
  sensitive   = true
  value       = azurerm_servicebus_queue_authorization_rule.this
}

output "resource_role_assignments" {
  description = "The role assignments created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment#attributes-reference"
  # The AzureRM attribute names are kept so that existing references keep working.
  value = { for key, assignment in azapi_resource.role_assignments : key => {
    id                                     = assignment.id
    name                                   = assignment.name
    scope                                  = assignment.parent_id
    principal_id                           = assignment.body.properties.principalId
    principal_type                         = try(assignment.body.properties.principalType, null)
    role_definition_id                     = assignment.body.properties.roleDefinitionId
    description                            = try(assignment.body.properties.description, null)
    condition                              = try(assignment.body.properties.condition, null)
    condition_version                      = try(assignment.body.properties.conditionVersion, null)
    delegated_managed_identity_resource_id = try(assignment.body.properties.delegatedManagedIdentityResourceId, null)
    skip_service_principal_aad_check       = local.total_role_assignments[key].role_params.skip_service_principal_aad_check
  } }
}

output "resource_topics" {
  description = "The service bus topics created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic.html#attributes-reference"
  value       = azurerm_servicebus_topic.this
}

output "resource_topics_authorization_rules" {
  description = "The service bus topics authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic_authorization_rule#attributes-reference"
  sensitive   = true
  value       = azurerm_servicebus_topic_authorization_rule.this
}

output "resource_topics_subscriptions" {
  description = "The service bus topic subscriptions created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_subscription#attributes-reference"
  value       = merge(azurerm_servicebus_subscription.base_topics, azurerm_servicebus_subscription.forward_topics)
}
