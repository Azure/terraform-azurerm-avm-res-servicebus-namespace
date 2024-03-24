variable "queues" {
  type = map(object({
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
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. A map of queues to create. The map key is used as the name of the queue.
  The name of the queue must be unique among topics and queues within the namespace.
    
  - `lock_duration`                           - (Optional) - Its minimum and default value is `PT1M` (1 minute). Maximum value is `PT5M` (5 minutes). The ISO 8601 timespan duration of a peek-lock; that is, the amount of time that the message is locked for other receivers.
  - `max_message_size_in_kilobytes`           - (Optional) - Always set to `256` for Standard and Basic by Azure. It's mininum and also defaults is `1024` with maximum value of `102400` for Premium. Integer value which controls the maximum size of a message allowed on the queue.
  - `max_size_in_megabytes`                   - (Optional) - Defaults to `1024`. Possible values are `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960` and `81920`. Integer value which controls the size of memory allocated for the queue.
  - `requires_duplicate_detection`            - (Optional) - Always set to `false` for Basic by Azure. It Defaults to `false` for the rest of skus. Boolean flag which controls whether the Queue requires duplicate detection. Changing this forces a new resource to be created.
  - `requires_session`                        - (Optional) - Always set to `false` for Basic by Azure. It Defaults to `false` for the rest of skus. Boolean flag which controls whether the Queue requires sessions. This will allow ordered handling of unbounded sequences of related messages. With sessions enabled a queue can guarantee first-in-first-out delivery of messages. Changing this forces a new resource to be created.
  - `default_message_ttl`                     - (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this queue. This is the default value used when TTL is not set on message itself.
  - `dead_lettering_on_message_expiration`    - (Optional) - Defaults to `false`. Boolean flag which controls whether the Queue has dead letter support when a message expires.
  - `duplicate_detection_history_time_window` - (Optional) - Defaults to `PT10M` (10 minutes). Minimun of `PT20S` (seconds) and Maximun of `P7D` (7 days). The ISO 8601 timespan duration during which duplicates can be detected.
  - `max_delivery_count`                      - (Optional) - Defaults to `10`. Minimum of `1` and Maximun of `2147483647`. Integer value which controls when a message is automatically dead lettered.
  - `status`                                  - (Optional) - Defaults to `Active`. The status of the Queue. Possible values are Active, Creating, Deleting, Disabled, ReceiveDisabled, Renaming, SendDisabled, Unknown.
  - `enable_batched_operations`               - (Optional) - Defaults to `true`. Boolean flag which controls whether server-side batched operations are enabled.
  - `auto_delete_on_idle`                     - (Optional) - Always set to `null` when Basic. It Defaults to `null` for the rest of skus. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.
  - `enable_partitioning`                     - (Optional) - Defaults to `false` for Basic and Standard. For Premium if premium_messaging_partitions is greater than `1` it will always be set to true if not it will be set to `false`. Boolean flag which controls whether to enable the queue to be partitioned across multiple message brokers. Changing this forces a new resource to be created. 
  - `enable_express`                          - (Optional) - Always set to `false` for Premium and Basic by Azure. Defaults to `false` for Standard. Boolean flag which controls whether Express Entities are enabled. An express queue holds a message in memory temporarily before writing it to persistent storage. It requires requires_duplicate_detection to be set to `false`
  - `forward_to`                              - (Optional) - Always set to `false` for Basic by Azure. It Defaults to `null` for the rest of skus. The name of a Queue or Topic to automatically forward messages to. It cannot be enabled if requires_session is enabled.
  - `forward_dead_lettered_messages_to`       - (Optional) - Defaults to `null`. The name of a Queue or Topic to automatically forward dead lettered messages to

  - `authorization_rules` - (Optional) - Defaults to `{}`. Map key is used as the name of the authorizaton rule.
    - `send`   = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Queue?
    - `listen` = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Queue? 
    - `manage` = (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Queue?
  
  - `role_assignments` - (Optional) - Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `role_definition_id_or_name`             = (Required) - The ID or name of the role definition to assign to the principal.
    - `principal_id`                           = (Required) - It's a GUID - The ID of the principal to assign the role to. 
    - `description`                            = (Optional) - Defaults to `null`. The description of the role assignment.
    - `delegated_managed_identity_resource_id` = (Optional) - Defaults to `null`. The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross tenant scenario. Changing this forces a new resource to be created.
    - `skip_service_principal_aad_check`       = (Optional) - Defaults to `false`. If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. 

  Example Inputs:
  ```hcl
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
  DESCRIPTION

  validation {
    condition = alltrue([
      for _, v in var.queues :
      v.forward_to != null && v.requires_session ? false : true
    ])
    error_message = "Forwarding to another queue or topic is not supported when requires_session is set to true."
  }

  validation {
    condition = alltrue([
      for _, v in var.queues :
      contains(["Active", "Creating", "Deleting", "Disabled", "ReceiveDisabled", "Renaming", "SendDisabled", "Unknown"], v.status)
    ])
    error_message = "The status parameter can only be `Active`, `Creating`, `Deleting`, `Disabled`, `ReceiveDisabled`, `Renaming`, `SendDisabled`, `Unknown`."
  }

  validation {
    condition = alltrue([
      for _, v in var.queues :
      contains([1024, 2048, 3072, 4096, 5120, 10240, 20480, 40960, 81920], v.max_size_in_megabytes)
    ])
    error_message = "The max_size_in_megabytes parameter must be one of `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960`, `81920`."
  }

  validation {
    condition = alltrue([
      for _, v in var.queues :
      1 <= v.max_delivery_count && 2147483647 >= v.max_delivery_count
    ])
    error_message = "value of max_delivery_count must be between 1 and 2147483647."
  }

  validation {
    condition = alltrue(flatten([
      for queue_name, queue_params in var.queues :
      [
        for k, v in queue_params.role_assignments :
        v.role_definition_id_or_name != null
      ]
    ]))
    error_message = "Role definition id or name must be set"
  }

  validation {
    condition = alltrue(flatten([
      for queue_name, queue_params in var.queues :
      [
        for k, v in queue_params.role_assignments :
        can(regex("^([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})$", v.principal_id))
      ]
    ]))
    error_message = "principal_id must be a valid GUID"
  }
}
