variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_analytics_destination_type           = optional(string, "Dedicated")
    log_groups                               = optional(set(string), ["allLogs"])
    metric_groups                            = optional(set(string), ["AllMetrics"])
  }))
  default  = {}
  nullable = false
  description = <<DESCRIPTION
    A map of diagnostic settings to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

    map(
      object({
        name                                     = Optional. The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
        log_categories                           = Optional. Defaults to `[]`. A set of log categories to export. Possible values are: `ApplicationMetricsLogs`, `RuntimeAuditLogs`, `VNetAndIPFilteringLogs` or `OperationalLogs`.
        log_groups                               = Optional. Ignored if log_categories is set, if not it defaults to `["allLogs"]`. A set of log groups to send to export.
        metric_groups                            = Optional. Defaults to `["AllMetrics"]`. A set of metric groups to export.
        log_analytics_destination_type           = Optional. Defaults to `Dedicated`. The destination log analytics workspace table for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
        workspace_resource_id                    = Optional. The resource ID of the log analytics workspace to send logs and metrics to.
        storage_account_resource_id              = Optional. The resource ID of the storage account to send logs and metrics to.
        event_hub_authorization_rule_resource_id = Optional. The resource ID of the event hub authorization rule to send logs and metrics to.
        event_hub_name                           = Optional. The name of the event hub. If none is specified, the default event hub will be selected.
        marketplace_partner_resource_id          = Optional. The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
      })
    )

    > Note: See more in CLI: az monitor diagnostic-settings categories list --resource {serviceBusNamespaceResourceId}

    Example Inputs:
    ```terraform
    diagnostic_settings = {
      diagnostic1 = {
        event_hub_name                           = "hub-name"
        log_analytics_destination_type           = "Dedicated"
        name                                     = "diagnostics"
        event_hub_authorization_rule_resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.EventHub/namespaces/{eventHubNamespaceName}/authorizationRules/{authorizationRuleName}"

        #log_categories = ["ApplicationMetricsLogs", "RuntimeAuditLogs", "VNetAndIPFilteringLogs", "OperationalLogs"]

        log_groups                  = ["allLogs"]
        metric_groups               = ["AllMetrics"]
        workspace_resource_id       = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
        storage_account_resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}"
      }
    }
    ```
    
  DESCRIPTION

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      alltrue([
        for c in v.metric_groups : 
        c == null ? false : contains(["AllMetrics"], c)
      ])
    ])
    error_message = "The metric_groups parameter if specified can only be `AllMetrics`."
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      alltrue([
        for c in v.log_groups : 
        c == null ? false : contains(["allLogs"], c)
      ])
    ])
    error_message = "The log_groups parameter if specified can only be `allLogs`."
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      alltrue([
        for c in v.log_categories : 
        contains(["ApplicationMetricsLogs", "RuntimeAuditLogs", "VNetAndIPFilteringLogs", "OperationalLogs"], c)
      ])
    ])
    error_message = "The log_categories parameter if specified can only be `ApplicationMetricsLogs`, `RuntimeAuditLogs`, `VNetAndIPFilteringLogs` or `OperationalLogs`."
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)
    ])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }

  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || (v.event_hub_name != null && v.event_hub_authorization_rule_resource_id != null) || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id` and `event_hub_name` together, must be set."
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      v.log_categories != null || v.log_groups != null || v.metric_groups != null
    ])
    error_message = "At least one of `log_categories`, `log_groups`, or `metric_groups` must be set."
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      v.storage_account_resource_id == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.Storage/storageAccounts/.+$", v.storage_account_resource_id))
    ])
    error_message = "The storage_account_resource_id if specified must have the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}"
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      v.workspace_resource_id == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.OperationalInsights/workspaces/.+$", v.workspace_resource_id))
    ])
    error_message = "The workspace_resource_id if specified must have the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
  }

  validation {
    condition     = alltrue([
      for _, v in var.diagnostic_settings : 
      v.event_hub_authorization_rule_resource_id == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.EventHub/namespaces/.+/authorizationRules/.+$", v.event_hub_authorization_rule_resource_id))
    ])
    error_message = "The event_hub_authorization_rule_resource_id if specified must have the format /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.EventHub/namespaces/{eventHubNamespaceName}/authorizationRules/{authorizationRuleName}"
  }
}