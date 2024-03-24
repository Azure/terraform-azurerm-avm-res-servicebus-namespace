<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-servicebus-namespace

Module to deploy key vaults, keys and secrets in Azure.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_private_endpoint.this_managed_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint.this_unmanaged_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_servicebus_namespace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace) (resource)
- [azurerm_servicebus_namespace_authorization_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace_authorization_rule) (resource)
- [azurerm_servicebus_queue.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue) (resource)
- [azurerm_servicebus_queue_authorization_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_queue_authorization_rule) (resource)
- [azurerm_servicebus_subscription.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_subscription) (resource)
- [azurerm_servicebus_topic.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic) (resource)
- [azurerm_servicebus_topic_authorization_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_topic_authorization_rule) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description:     Specifies the name of the ServiceBus Namespace resource.   
    Changing this forces a new resource to be created.   
    Name must only contain letters, numbers, and hyphens and be between 6 and 50 characteres long. Also, it must not start or end with a hyphen.

    Example Inputs: sb-sharepoint-prod-westus-001  
    See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftservicebus

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description:     The name of the resource group in which to create this resource.   
    Changing this forces a new resource to be created.  
    Name must be less than 90 characters long and must only contain underscores, hyphens, periods, parentheses, letters, or digits.

    Example Inputs: rg-sharepoint-prod-westus-001  
    See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftresources

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_authorization_rules"></a> [authorization\_rules](#input\_authorization\_rules)

Description:     Defaults to `{}`. Manages a ServiceBus Namespace authorization Rule within a ServiceBus. Map key is used as the name of the authorizaton rule. The following properties can be specified:

    authorization\_rules = map(object({  
      send   = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Namespace?  
      listen = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Namespace?   
      manage = (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Namespace?
    }))

    Example Inputs:
    ```terraform
    authorization_rules = {
      testRule = {
        send   = true
        listen = true
        manage = true
      }
    }
    
```

Type:

```hcl
map(object({
    send   = optional(bool, false)
    listen = optional(bool, false)
    manage = optional(bool, false)
  }))
```

Default: `{}`

### <a name="input_capacity"></a> [capacity](#input\_capacity)

Description:     Always set to `0` for Standard and Basic. Defaults to `1` for Premium. Specifies the capacity.   
    When sku is Premium, capacity can be 1, 2, 4, 8 or 16.

Type: `number`

Default: `null`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description:     Defaults to `null`. Ignored for Basic and Standard. Defines a customer managed key to use for encryption.

    object({  
      key\_name                           = (Required) - The key name for the customer managed key in the key vault.  
      user\_assigned\_identity\_resource\_id = (Required) - The user assigned identity to use when access the key vault  
      key\_vault\_resource\_id              = (Required) - The full Azure Resource ID of the key\_vault where the customer managed key will be referenced from.  
      key\_version                        = (Optional) - Defaults to `null` which is the latest version of the key. The version of the key to use  
      infrastructure\_encryption\_enabled  = (Optional) - Defaults to `true`. Used to specify whether enable Infrastructure Encryption (Double Encryption). Changing this forces a new resource to be created.
    })

    > Note: Remember to assign permission to the managed identity to access the key vault key. The Key vault used must have enabled soft delete and purge protection

    Example Inputs:
    ```terraform
    customer_managed_key = {
      infrastructure_encryption_enabled  = true
      key_name                           = "sample-customer-key"
      key_version                        = 03c89971825b4a0d84905c3597512260
      key_vault_resource_id              = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}"
      user_assigned_identity_resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"
    }
    
```

Type:

```hcl
object({
    key_vault_resource_id              = string
    key_name                           = string
    user_assigned_identity_resource_id = string
    infrastructure_encryption_enabled  = optional(bool, true)
    key_version                        = optional(string, null)
  })
```

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:     Defaults to `{}`. A map of diagnostic settings to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

    map(  
      object({  
        name                                     = (Optional) - The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.  
        log\_categories                           = (Optional) - Defaults to `[]`. A set of log categories to export. Possible values are: `ApplicationMetricsLogs`, `RuntimeAuditLogs`, `VNetAndIPFilteringLogs` or `OperationalLogs`.  
        log\_groups                               = (Optional) - Defaults to `[]` if log\_categories is set, if not it defaults to `["allLogs", "audit"]`. A set of log groups to send to export. Possible values are `allLogs` and `audit`.  
        metric\_groups                            = (Optional) - Defaults to `["AllMetrics"]`. A set of metric groups to export.  
        log\_analytics\_destination\_type           = (Optional) - Defaults to `Dedicated`. The destination log analytics workspace table for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.  
        workspace\_resource\_id                    = (Optional) - The resource ID of the log analytics workspace to send logs and metrics to.  
        storage\_account\_resource\_id              = (Optional) - The resource ID of the storage account to send logs and metrics to.  
        event\_hub\_authorization\_rule\_resource\_id = (Optional) - The resource ID of the event hub authorization rule to send logs and metrics to.  
        event\_hub\_name                           = (Optional) - The name of the event hub. If none is specified, the default event hub will be selected.  
        marketplace\_partner\_resource\_id          = (Optional) - The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
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

        metric_groups               = ["AllMetrics"]
        log_groups                  = ["allLogs", "audit"]
        workspace_resource_id       = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName}"
        storage_account_resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}"
      }
    }
    
```

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description:     Defaults to `true`. This variable controls whether or not telemetry is enabled for the module.  
    For more information see https://aka.ms/avm/telemetryinfo.  
    If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_local_auth_enabled"></a> [local\_auth\_enabled](#input\_local\_auth\_enabled)

Description: Defaults to `true`. Whether or not SAS authentication is enabled for the Service Bus namespace.

Type: `bool`

Default: `true`

### <a name="input_location"></a> [location](#input\_location)

Description:     Azure region where the resource should be deployed.  
    If null, the location will be inferred from the resource group location.  
    Changing this forces a new resource to be created.  

    Example Inputs: eastus  
    See more in CLI: az account list-locations -o table --query "[].name"

Type: `string`

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:     Defaults to `null`. Controls the Resource Lock configuration for this resource.   
    If specified, it will be inherited by child resources unless overriden when creating those child resources.   
    The following properties can be specified:

    object({  
      kind = (Required) - The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.  
      name = (Optional) - The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
    })

    Example Inputs:
    ```terraform
    lock = {
      kind = "CanNotDelete"
      name = "This resource cannot be deleted easily"
    }
    
```

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:     Defaults to `{}`. Controls the Managed Identity configuration on this resource. The following properties can be specified:

    object({  
      system\_assigned            = (Optional) - Defaults to `false`. Specifies if the System Assigned Managed Identity should be enabled.  
      user\_assigned\_resource\_ids = (Optional) - Defaults to `[]`. Specifies a set of User Assigned Managed Identity resource IDs to be assigned to this resource.
    })

    Example Inputs:
    ```terraform
    managed_identities = {
      system_assigned            = true
      user_assigned_resource_ids = ["/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"]
    }
    
```

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_minimum_tls_version"></a> [minimum\_tls\_version](#input\_minimum\_tls\_version)

Description: Defaults to `1.2`. The minimum supported TLS version for this Service Bus Namespace. Valid values are: 1.0, 1.1 and 1.2.

Type: `string`

Default: `"1.2"`

### <a name="input_network_rule_config"></a> [network\_rule\_config](#input\_network\_rule\_config)

Description:     Defaults to `{}`. Ignored for Basic and Standard. Defines the network rules configuration for the resource.

    object({  
      trusted\_services\_allowed = (Optional) - Are Azure Services that are known and trusted for this resource type are allowed to bypass firewall configuration?   
      cidr\_or\_ip\_rules         = (Optional) - Defaults to `[]`. One or more IP Addresses, or CIDR Blocks which should be able to access the ServiceBus Namespace.  
      default\_action           = (Optional) - Defaults to `Allow`. Specifies the default action for the Network Rule Set. Possible values are Allow and Deny.

      Defaults to `[]`.  
      network\_rules = set(object({  
        subnet\_id                            = (Required) - The Subnet ID which should be able to access this ServiceBus Namespace.  
        ignore\_missing\_vnet\_service\_endpoint = (Optional) - Defaults to `false`. Should the ServiceBus Namespace Network Rule Set ignore missing Virtual Network Service Endpoint option in the Subnet?
      }))
    })

    > Note: Remember to enable Microsoft.KeyVault service endpoint on the subnet if ignore\_missing\_vnet\_service\_endpoint is set to `false`.

    Example Inputs:
    ```terraform
    network_rule_config = {
      trusted_services_allowed = true
      default_action           = "Allow"
      cidr_or_ip_rules         = ["79.0.0.0", "80.0.0.0/24"]

      network_rules = [
        {
          ignore_missing_vnet_service_endpoint = false
          subnet_id                            = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}"
        }
      ]
    }
    
```

Type:

```hcl
object({
    trusted_services_allowed = optional(bool, false)
    cidr_or_ip_rules         = optional(set(string), [])
    default_action           = optional(string, "Allow")

    network_rules = optional(set(object({
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })), [])
  })
```

Default: `{}`

### <a name="input_premium_messaging_partitions"></a> [premium\_messaging\_partitions](#input\_premium\_messaging\_partitions)

Description:     Always set to `0` for Standard and Basic. Defaults to `1` for Premium. Specifies the number of messaging partitions.   
    Possible values when Premium are 1, 2, and 4. Changing this forces a new resource to be created.

Type: `number`

Default: `null`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description:     Default to `{}`. Ignored for Basic and Standard. A map of private endpoints to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

    - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
    - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
    - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
    - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
    - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
    - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
    - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
    - `application_security_group_associations` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
    - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
    - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
    - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the resource.
    - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
      - `name` - The name of the IP configuration.
      - `private_ip_address` - The private IP address of the IP configuration.

Type:

```hcl
map(object({
    tags = optional(map(string), {})

    lock = optional(object({
      inherit_lock_from_namespace = optional(bool, true)
      kind                        = optional(string, null)
      name                        = optional(string, null)
    }), {})

    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string

      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})

    subnet_resource_id = string

    name                                    = optional(string, null)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)

    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_private_endpoints_manage_dns_zone_group"></a> [private\_endpoints\_manage\_dns\_zone\_group](#input\_private\_endpoints\_manage\_dns\_zone\_group)

Description: Default to true. Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy.

Type: `bool`

Default: `true`

### <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled)

Description: Defaults to `true`. Is public network access enabled for the Service Bus Namespace?

Type: `bool`

Default: `true`

### <a name="input_queues"></a> [queues](#input\_queues)

Description:     Defaults to `{}`. A map of queues to create. The map key is used as the name of the queue.  
    The name of the queue must be unique among topics and queues within the namespace.

    map(  
      object({  
        lock\_duration                            = (Optional) - Its minimum and default value is `PT1M` (1 minute). Maximum value is `PT5M` (5 minutes). The ISO 8601 timespan duration of a peek-lock; that is, the amount of time that the message is locked for other receivers.  
        max\_message\_size\_in\_kilobytes            = (Optional) - Always set to `256` for Standard and Basic by Azure. It's mininum and also defaults is `1024` with maximum value of `102400` for Premium. Integer value which controls the maximum size of a message allowed on the queue.  
        max\_size\_in\_megabytes                    = (Optional) - Defaults to `1024`. Possible values are `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960` and `81920`. Integer value which controls the size of memory allocated for the queue.  
        requires\_duplicate\_detection             = (Optional) - Always set to `false` for Basic by Azure. It Defaults to `false` for the rest of skus. Boolean flag which controls whether the Queue requires duplicate detection. Changing this forces a new resource to be created.  
        requires\_session                         = (Optional) - Always set to `false` for Basic by Azure. It Defaults to `false` for the rest of skus. Boolean flag which controls whether the Queue requires sessions. This will allow ordered handling of unbounded sequences of related messages. With sessions enabled a queue can guarantee first-in-first-out delivery of messages. Changing this forces a new resource to be created.  
        default\_message\_ttl                      = (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this queue. This is the default value used when TTL is not set on message itself.  
        dead\_lettering\_on\_message\_expiration     = (Optional) - Defaults to `false`. Boolean flag which controls whether the Queue has dead letter support when a message expires.  
        duplicate\_detection\_history\_time\_window  = (Optional) - Defaults to `PT10M` (10 minutes). Minimun of `PT20S` (seconds) and Maximun of `P7D` (7 days). The ISO 8601 timespan duration during which duplicates can be detected.  
        max\_delivery\_count                       = (Optional) - Defaults to `10`. Minimum of `1` and Maximun of `2147483647`. Integer value which controls when a message is automatically dead lettered.  
        status                                   = (Optional) - Defaults to `Active`. The status of the Queue. Possible values are Active, Creating, Deleting, Disabled, ReceiveDisabled, Renaming, SendDisabled, Unknown.  
        enable\_batched\_operations                = (Optional) - Defaults to `true`. Boolean flag which controls whether server-side batched operations are enabled.  
        auto\_delete\_on\_idle                      = (Optional) - Always set to `null` when Basic. It Defaults to `null` for the rest of skus. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.  
        enable\_partitioning                      = (Optional) - Defaults to `false` for Basic and Standard. For Premium if premium\_messaging\_partitions is greater than `1` it will always be set to true if not it will be set to `false`. Boolean flag which controls whether to enable the queue to be partitioned across multiple message brokers. Changing this forces a new resource to be created.   
        enable\_express                           = (Optional) - Always set to `false` for Premium and Basic by Azure. Defaults to `false` for Standard. Boolean flag which controls whether Express Entities are enabled. An express queue holds a message in memory temporarily before writing it to persistent storage. It requires requires\_duplicate\_detection to be set to `false`  
        forward\_to                               = (Optional) - Always set to `false` for Basic by Azure. It Defaults to `null` for the rest of skus. The name of a Queue or Topic to automatically forward messages to. It cannot be enabled if requires\_session is enabled.  
        forward\_dead\_lettered\_messages\_to        = (Optional) - Defaults to `null`. The name of a Queue or Topic to automatically forward dead lettered messages to

        Defaults to `{}`. Map key is used as the name of the authorizaton rule.  
        authorization\_rules = map(  
          object({   
            send   = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Queue?  
            listen = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Queue?   
            manage = (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Queue?
          })
        )  
      
        Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.  
        role\_assignments = map(  
          object({  
            role\_definition\_id\_or\_name             = (Required) - The ID or name of the role definition to assign to the principal.  
            principal\_id                           = (Required) - It's a GUID - The ID of the principal to assign the role to.   
            description                            = (Optional) - Defaults to `null`. The description of the role assignment.  
            delegated\_managed\_identity\_resource\_id = (Optional) - Defaults to `null`. The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross tenant scenario. Changing this forces a new resource to be created.  
            skip\_service\_principal\_aad\_check       = (Optional) - Defaults to `false`. If the principal\_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal\_id is a Service Principal identity.
          })
        )
      })
    )

    Example Inputs:
    ```terraform
    queues = {
      testQueue = {
        auto_delete_on_idle                     = "P7D"
        dead_lettering_on_message_expiration    = true
        default_message_ttl                     = "PT5M"
        duplicate_detection_history_time_window = "PT5M"
        enable_batched_operations               = true
        enable_express                          = true
        enable_partitioning                     = true
        lock_duration                           = "PT5M"
        requires_duplicate_detection            = true
        requires_session                        = false
        max_delivery_count                      = 10
        max_message_size_in_kilobytes           = 1024
        max_size_in_megabytes                   = 1024
        status                                  = "Active"
        forward_to                              = "forwardQueue"
        forward_dead_lettered_messages_to       = "forwardQueue"

        role_assignments = {
          "key" = {
            skip_service_principal_aad_check = false
            role_definition_id_or_name       = "Contributor"
            description                      = "This is a test role assignment"
            principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
          }
        }

        authorization_rules = {
          testRule = {
            send   = true
            listen = true
            manage = true
          }
        }
      }
    }
    
```

Type:

```hcl
map(object({
    max_delivery_count                      = optional(number, 10)
    enable_batched_operations               = optional(bool, true)
    requires_duplicate_detection            = optional(bool, false)
    requires_session                        = optional(bool, false)
    dead_lettering_on_message_expiration    = optional(bool, false)
    enable_partitioning                     = optional(bool, null)
    enable_express                          = optional(bool, null)
    max_message_size_in_kilobytes           = optional(number, null)
    default_message_ttl                     = optional(string, null)
    forward_to                              = optional(string, null)
    forward_dead_lettered_messages_to       = optional(string, null)
    auto_delete_on_idle                     = optional(string, null)
    max_size_in_megabytes                   = optional(number, 1024)
    lock_duration                           = optional(string, "PT1M")
    duplicate_detection_history_time_window = optional(string, "PT10M")
    status                                  = optional(string, "Active")

    authorization_rules = optional(map(object({
      send   = optional(bool, false)
      listen = optional(bool, false)
      manage = optional(bool, false)
    })), {})

    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string

      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
```

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:     Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

    map(  
      object({  
        role\_definition\_id\_or\_name             = (Required) - The ID or name of the role definition to assign to the principal.  
        principal\_id                           = (Required) - It's a GUID - The ID of the principal to assign the role to.   
        description                            = (Optional) - Defaults to `null`. The description of the role assignment.  
        delegated\_managed\_identity\_resource\_id = (Optional) - Defaults to `null`. The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross tenant scenario. Changing this forces a new resource to be created.  
        skip\_service\_principal\_aad\_check       = (Optional) - Defaults to `false`. If the principal\_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal\_id is a Service Principal identity.
      })
    )

    > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

    Example Inputs:
    ```terraform
    role_assignments = {
      "key" = {
        skip_service_principal_aad_check = false
        role_definition_id_or_name       = "Contributor"
        description                      = "This is a test role assignment"
        principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
      }
    }
    
```

Type:

```hcl
map(object({
    role_definition_id_or_name = string
    principal_id               = string

    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_sku"></a> [sku](#input\_sku)

Description:     Defaults to `Standard`. Defines which tier to use. Options are Basic, Standard or Premium.   
    Please note that setting this field to Premium will force the creation of a new resource.

Type: `string`

Default: `"Standard"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description:     Defaults to `{}`. A mapping of tags to assign to the resource. These tags will propagate to any child resource unless overriden when creating the child resource

    Example Inputs:
    ```terraform
    tags = {
      environment = "testing"
    }
    
```

Type: `map(string)`

Default: `{}`

### <a name="input_topics"></a> [topics](#input\_topics)

Description:     Defaults to `{}`. Ignored for Basic. A map of topics to create. The map key is used as the name of the topic.  
    The name of the topic must be unique among topics and queues within the namespace.

    map(  
      object({  
        max\_message\_size\_in\_kilobytes            = (Optional) - Always set to `256` for Standard by Azure. It's mininum and also defaults is `1024` with maximum value of `102400` for Premium. Integer value which controls the maximum size of a message allowed on the Topic.  
        max\_size\_in\_megabytes                    = (Optional) - Defaults to `1024`. Possible values are `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960` and `81920`. Integer value which controls the size of memory allocated for the Topic.  
        requires\_duplicate\_detection             = (Optional) - Defaults to `false`. Boolean flag which controls whether the Topic requires duplicate detection. Changing this forces a new resource to be created.  
        default\_message\_ttl                      = (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this topic. This is the default value used when TTL is not set on message itself.  
        duplicate\_detection\_history\_time\_window  = (Optional) - Defaults to `PT10M` (10 minutes). Minimun of `PT20S` (seconds) and Maximun of `P7D` (7 days). The ISO 8601 timespan duration during which duplicates can be detected.  
        status                                   = (Optional) - Defaults to `Active`. The status of the Topic. Possible values are Active, Creating, Deleting, Disabled, ReceiveDisabled, Renaming, SendDisabled, Unknown.  
        enable\_batched\_operations                = (Optional) - Defaults to `true`. Boolean flag which controls whether server-side batched operations are enabled.  
        auto\_delete\_on\_idle                      = (Optional) - Defaults to `null`. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.  
        enable\_partitioning                      = (Optional) - Defaults to `false` for Standard. For Premium if premium\_messaging\_partitions is greater than `1` it will always be set to true if not it will be set to `false`. Boolean flag which controls whether to enable the topic to be partitioned across multiple message brokers. Changing this forces a new resource to be created.   
        enable\_express                           = (Optional) - Defaults to `false` for Standard. Always set to `false` for Premium. Boolean flag which controls whether Express Entities are enabled. An express topic holds a message in memory temporarily before writing it to persistent storage.  
        support\_ordering                         = (Optional) - Defaults to `false`. Boolean flag which controls whether the Topic supports ordering.

        Defaults to `{}`. Map key is used as the name of the authorizaton rule.  
        authorization\_rules = map(  
          object({  
            send   = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Topic?  
            listen = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Topic?   
            manage = (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Topic?
          })
        )

        Defaults to `{}`. Map key is used as the name of the subscription.  
        subscriptions = map(  
          object({  
            max\_delivery\_count                        = (Optional) - Defaults to `10`. Minimum of `1` and Maximun of `2147483647`. Integer value which controls when a message is automatically dead lettered.  
            dead\_lettering\_on\_filter\_evaluation\_error = (Optional) - Defaults to `true`. Boolean flag which controls whether the Subscription has dead letter support on filter evaluation exceptions  
            dead\_lettering\_on\_message\_expiration      = (Optional) - Defaults to `false`. Boolean flag which controls whether the Subscription has dead letter support when a message expires.  
            enable\_batched\_operations                 = (Optional) - Defaults to `true`. Boolean flag which controls whether the Subscription supports batched operations.  
            requires\_session                          = (Optional) - Defaults to `false`. Boolean flag which controls whether this Subscription supports the concept of a session. Changing this forces a new resource to be created.  
            forward\_to                                = (Optional) - Defaults to `null`. The name of a Queue or Topic to automatically forward messages to.  
            forward\_dead\_lettered\_messages\_to         = (Optional) - Defaults to `null`. The name of a Queue or Topic to automatically forward dead lettered messages to  
            auto\_delete\_on\_idle                       = (Optional) - Defaults to `null`. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.  
            default\_message\_ttl                       = (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this queue. This is the default value used when TTL is not set on message itself.  
            lock\_duration                             = (Optional) - Its minimum and default value is `PT1M` (1 minute). Maximum value is `PT5M` (5 minutes). The ISO 8601 timespan duration of a peek-lock; that is, the amount of time that the message is locked for other receivers.  
            status                                    = (Optional) - Defaults to `Active`. The status of the Subscription. Possible values are Active, ReceiveDisabled, Disabled.
          })
        )

        Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.  
        role\_assignments = map(  
          object({  
            role\_definition\_id\_or\_name             = (Required) - The ID or name of the role definition to assign to the principal.  
            principal\_id                           = (Required) - It's a GUID - The ID of the principal to assign the role to.   
            description                            = (Optional) - Defaults to `null`. The description of the role assignment.  
            delegated\_managed\_identity\_resource\_id = (Optional) - Defaults to `null`. The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross tenant scenario. Changing this forces a new resource to be created.  
            skip\_service\_principal\_aad\_check       = (Optional) - Defaults to `false`. If the principal\_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal\_id is a Service Principal identity.
          })
        )
      })
    )

    Example Inputs:
    ```terraform
    topics = {
      testTopic = {
        auto_delete_on_idle                     = "P7D"
        default_message_ttl                     = "PT5M"
        duplicate_detection_history_time_window = "PT5M"
        enable_batched_operations               = true
        enable_express                          = false
        enable_partitioning                     = true
        requires_duplicate_detection            = true
        max_message_size_in_kilobytes           = 1024
        max_size_in_megabytes                   = 1024
        status                                  = "Active"
        support_ordering                        = true

        subscriptions = {
          testSubscription = {
            dead_lettering_on_filter_evaluation_error = true
            dead_lettering_on_message_expiration      = true
            default_message_ttl                       = "PT5M"
            enable_batched_operations                 = true
            lock_duration                             = "PT1M"
            max_delivery_count                        = 100
            status                                    = "Active"
            auto_delete_on_idle                       = "P7D"
            requires_session                          = false
            forward_dead_lettered_messages_to         = "forwardTopic"
            forward_to                                = "forwardTopic"
          }
        }

        role_assignments = {
          "key" = {
            skip_service_principal_aad_check = false
            role_definition_id_or_name       = "Contributor"
            description                      = "This is a test role assignment"
            principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
          }
        }
        
        authorization_rules = {
          testRule = {
            send   = true
            listen = true
            manage = true
          }
        }
      }
    }
    
```

Type:

```hcl
map(object({
    enable_batched_operations               = optional(bool, true)
    requires_duplicate_detection            = optional(bool, false)
    enable_partitioning                     = optional(bool, null)
    enable_express                          = optional(bool, null)
    support_ordering                        = optional(bool, false)
    max_message_size_in_kilobytes           = optional(number, null)
    default_message_ttl                     = optional(string, null)
    auto_delete_on_idle                     = optional(string, null)
    max_size_in_megabytes                   = optional(number, 1024)
    duplicate_detection_history_time_window = optional(string, "PT10M")
    status                                  = optional(string, "Active")

    authorization_rules = optional(map(object({
      send   = optional(bool, false)
      listen = optional(bool, false)
      manage = optional(bool, false)
    })), {})

    subscriptions = optional(map(object({
      max_delivery_count                        = optional(number, 10)
      dead_lettering_on_filter_evaluation_error = optional(bool, true)
      enable_batched_operations                 = optional(bool, true)
      dead_lettering_on_message_expiration      = optional(bool, false)
      requires_session                          = optional(bool, false)
      forward_to                                = optional(string, null)
      forward_dead_lettered_messages_to         = optional(string, null)
      auto_delete_on_idle                       = optional(string, null)
      default_message_ttl                       = optional(string, null)
      lock_duration                             = optional(string, "PT1M")
      status                                    = optional(string, "Active")
    })), {})

    role_assignments = optional(map(object({
      role_definition_id_or_name = string
      principal_id               = string

      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
```

Default: `{}`

### <a name="input_zone_redundant"></a> [zone\_redundant](#input\_zone\_redundant)

Description:     Always set to `false` for Standard and Basic. Defaults to `true` for Premium. Whether or not this resource is zone redundant.   
    Changing this forces a new resource to be created.

Type: `bool`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The service bus namespace created

### <a name="output_resource_authorization_rules"></a> [resource\_authorization\_rules](#output\_resource\_authorization\_rules)

Description: The service bus namespace authorization rules created

### <a name="output_resource_diagnostic_settings"></a> [resource\_diagnostic\_settings](#output\_resource\_diagnostic\_settings)

Description: The diagnostic settings created

### <a name="output_resource_locks"></a> [resource\_locks](#output\_resource\_locks)

Description: The management locks created

### <a name="output_resource_private_endpoints"></a> [resource\_private\_endpoints](#output\_resource\_private\_endpoints)

Description: A map of the private endpoints created.

### <a name="output_resource_private_endpoints_application_security_group_association"></a> [resource\_private\_endpoints\_application\_security\_group\_association](#output\_resource\_private\_endpoints\_application\_security\_group\_association)

Description: The private endpoint application security group associations created

### <a name="output_resource_queues"></a> [resource\_queues](#output\_resource\_queues)

Description: The service bus queues created

### <a name="output_resource_queues_authorization_rules"></a> [resource\_queues\_authorization\_rules](#output\_resource\_queues\_authorization\_rules)

Description: The service bus queues authorization rules created

### <a name="output_resource_role_assignments"></a> [resource\_role\_assignments](#output\_resource\_role\_assignments)

Description: The role assignments created

### <a name="output_resource_topics"></a> [resource\_topics](#output\_resource\_topics)

Description: The service bus topics created

### <a name="output_resource_topics_authorization_rules"></a> [resource\_topics\_authorization\_rules](#output\_resource\_topics\_authorization\_rules)

Description: The service bus topics authorization rules created

### <a name="output_resource_topics_subscriptions"></a> [resource\_topics\_subscriptions](#output\_resource\_topics\_subscriptions)

Description: The service bus topic subscriptions created

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->