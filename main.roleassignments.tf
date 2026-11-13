locals {
  # Role names are matched case-insensitively, as the AzureRM provider matched them.
  role_definition_ids_by_name = length(local.total_role_assignments) > 0 ? {
    for definition in try(data.azapi_resource_list.role_definitions[0].output.results, []) : lower(definition.role_name) => definition.id...
  } : {}
  role_assignments = {
    for key, assignment in local.total_role_assignments : key => {
      name                                   = try(assignment.role_params.name, null)
      principal_id                           = assignment.role_params.principal_id
      description                            = assignment.role_params.description
      skip_service_principal_aad_check       = assignment.role_params.skip_service_principal_aad_check
      condition                              = try(assignment.role_params.condition, null)
      condition_version                      = try(assignment.role_params.condition_version, null)
      delegated_managed_identity_resource_id = assignment.role_params.delegated_managed_identity_resource_id
      # The AzureRM provider sent this principal type when the flag was set, which skips the Entra ID
      # existence check that fails for newly created service principals.
      principal_type = try(assignment.role_params.principal_type, null) == null && assignment.role_params.skip_service_principal_aad_check ? "ServicePrincipal" : try(assignment.role_params.principal_type, null)
      # Names resolve to IDs. Tenant-level IDs are qualified with the subscription, which is the form
      # Azure returns, so that the configuration and the deployed assignment compare equal.
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_params.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? try(local.role_definition_ids_by_name[lower(assignment.role_params.role_definition_id_or_name)][0], assignment.role_params.role_definition_id_or_name) :
        startswith(lower(assignment.role_params.role_definition_id_or_name), "/providers/") ? "/subscriptions/${data.azapi_client_config.current.subscription_id}${assignment.role_params.role_definition_id_or_name}" :
        assignment.role_params.role_definition_id_or_name
      )
    }
  }
  role_assignment_scopes = {
    for key, assignment in local.total_role_assignments : key => (
      assignment.scope_type == local.queue_scope_type ? try(azurerm_servicebus_queue.base_queues[assignment.queue_name].id, azurerm_servicebus_queue.forward_queues[assignment.queue_name].id) :
      assignment.scope_type == local.topic_scope_type ? azurerm_servicebus_topic.this[assignment.topic_name].id :
      assignment.scope_type == local.private_endpoint_scope_type && var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoints[assignment.pe_name].id :
      assignment.scope_type == local.private_endpoint_scope_type ? azapi_resource.private_endpoints_unmanaged_dns_zone_groups[assignment.pe_name].id :
      azapi_resource.this.id
    )
  }
}

data "azapi_client_config" "current" {}

# Role definitions are listed in the resource group rather than on the namespace, so the lookup does not
# wait for pending changes to the namespace and a role name that does not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(local.total_role_assignments) > 0 ? 1 : 0

  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = local.total_role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = local.role_assignment_scopes[each.key]
  type                 = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are
  # compared rather than the body, because Azure normalises role definition IDs. While the prior value
  # is null, as it is straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    condition                              = local.role_assignments[each.key].condition
    condition_version                      = local.role_assignments[each.key].condition_version
    delegated_managed_identity_resource_id = local.role_assignments[each.key].delegated_managed_identity_resource_id
    description                            = local.role_assignments[each.key].description
    principal_id                           = lower(local.role_assignments[each.key].principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_params.role_definition_id_or_name)
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

  lifecycle {
    # Upgraded assignments keep the GUID azurerm generated, while the interfaces module generates a
    # new one. Replacing the assignment would fail with ScopeLocked under a CanNotDelete lock.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), lower(local.role_definition_resource_substring))
      error_message = "The role definition `${each.value.role_params.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}
