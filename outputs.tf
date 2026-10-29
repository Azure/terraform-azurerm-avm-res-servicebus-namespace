output "resource" {
  description = "The service bus namespace created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace.html#attributes-reference"
  sensitive   = true
  value       = azurerm_servicebus_namespace.this
}

output "resource_authorization_rules" {
  description = "The service bus namespace authorization rules created. More info: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule#attributes-reference"
  sensitive   = true
  value       = azurerm_servicebus_namespace_authorization_rule.this
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
  value       = azurerm_servicebus_namespace.this.id
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
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_private_endpoints_application_security_group_association" {
  description = "The private endpoint application security group associations created"
  value       = azurerm_private_endpoint_application_security_group_association.this
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
