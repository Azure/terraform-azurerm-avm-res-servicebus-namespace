variable "topics" {
  type = map(object({
    name                                    = optional(string, null)
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
      name   = optional(string, null)
      send   = optional(bool, false)
      listen = optional(bool, false)
      manage = optional(bool, false)
    })), {})

    subscriptions = optional(map(object({
      name                                      = optional(string, null)
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
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
  Defaults to `{}`. Ignored for Basic. A map of topics to create.
  The name of the topic must be unique among topics and queues within the namespace.

  - `name`                                    - (Optional) - Defaults to `null`. Specifies the name of the ServiceBus Topic resource. Changing this forces a new resource to be created. If it is null it will use the map key as the name.
  - `max_message_size_in_kilobytes`           - (Optional) - Always set to `256` for Standard by Azure. It's mininum and also defaults is `1024` with maximum value of `102400` for Premium. Integer value which controls the maximum size of a message allowed on the Topic.
  - `max_size_in_megabytes`                   - (Optional) - Defaults to `1024`. Possible values are `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960` and `81920`. Integer value which controls the size of memory allocated for the Topic.
  - `requires_duplicate_detection`            - (Optional) - Defaults to `false`. Boolean flag which controls whether the Topic requires duplicate detection. Changing this forces a new resource to be created.
  - `default_message_ttl`                     - (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this topic. This is the default value used when TTL is not set on message itself.
  - `duplicate_detection_history_time_window` - (Optional) - Defaults to `PT10M` (10 minutes). Minimun of `PT20S` (seconds) and Maximun of `P7D` (7 days). The ISO 8601 timespan duration during which duplicates can be detected.
  - `status`                                  - (Optional) - Defaults to `Active`. The status of the Topic. Possible values are Active, Creating, Deleting, Disabled, ReceiveDisabled, Renaming, SendDisabled, Unknown.
  - `enable_batched_operations`               - (Optional) - Defaults to `true`. Boolean flag which controls whether server-side batched operations are enabled.
  - `auto_delete_on_idle`                     - (Optional) - Defaults to `null`. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.
  - `enable_partitioning`                     - (Optional) - Defaults to `false` for Standard. For Premium if premium_messaging_partitions is greater than `1` it will always be set to true if not it will be set to `false`. Boolean flag which controls whether to enable the topic to be partitioned across multiple message brokers. Changing this forces a new resource to be created. 
  - `enable_express`                          - (Optional) - Defaults to `false` for Standard. Always set to `false` for Premium. Boolean flag which controls whether Express Entities are enabled. An express topic holds a message in memory temporarily before writing it to persistent storage.
  - `support_ordering`                        - (Optional) - Defaults to `false`. Boolean flag which controls whether the Topic supports ordering.

  - `authorization_rules` - (Optional) - Defaults to `{}`. 
    - `name`   - (Optional) - Defaults to `null`. Specifies the name of the ServiceBus Topic Authorization Rule resource. Changing this forces a new resource to be created. If it is null it will use the map key as the name.
    - `send`   - (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Topic?
    - `listen` - (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Topic? 
    - `manage` - (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Topic?

  - `subscriptions - (Optional) - Defaults to `{}`.
    - `name`                                      - (Optional) - Defaults to `null`. Specifies the name of the ServiceBus Subscription resource. Changing this forces a new resource to be created. If it is null it will use the map key as the name.
    - `max_delivery_count`                        - (Optional) - Defaults to `10`. Minimum of `1` and Maximun of `2147483647`. Integer value which controls when a message is automatically dead lettered.
    - `dead_lettering_on_filter_evaluation_error` - (Optional) - Defaults to `true`. Boolean flag which controls whether the Subscription has dead letter support on filter evaluation exceptions
    - `dead_lettering_on_message_expiration`      - (Optional) - Defaults to `false`. Boolean flag which controls whether the Subscription has dead letter support when a message expires.
    - `enable_batched_operations`                 - (Optional) - Defaults to `true`. Boolean flag which controls whether the Subscription supports batched operations.
    - `requires_session`                          - (Optional) - Defaults to `false`. Boolean flag which controls whether this Subscription supports the concept of a session. Changing this forces a new resource to be created.
    - `forward_to`                                - (Optional) - Defaults to `null`. The name of a Queue or Topic to automatically forward messages to.
    - `forward_dead_lettered_messages_to`         - (Optional) - Defaults to `null`. The name of a Queue or Topic to automatically forward dead lettered messages to
    - `auto_delete_on_idle`                       - (Optional) - Defaults to `null`. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.
    - `default_message_ttl`                       - (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this queue. This is the default value used when TTL is not set on message itself.
    - `lock_duration`                             - (Optional) - Its minimum and default value is `PT1M` (1 minute). Maximum value is `PT5M` (5 minutes). The ISO 8601 timespan duration of a peek-lock; that is, the amount of time that the message is locked for other receivers.
    - `status`                                    - (Optional) - Defaults to `Active`. The status of the Subscription. Possible values are Active, ReceiveDisabled, Disabled.
  
  - `role_assignments - (Optional) - Defaults to `{}`. A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `role_definition_id_or_name`             - (Required) - The ID or name of the role definition to assign to the principal.
    - `principal_id`                           - (Required) - It's a GUID - The ID of the principal to assign the role to. 
    - `description`                            - (Optional) - Defaults to `null`. The description of the role assignment.
    - `delegated_managed_identity_resource_id` - (Optional) - Defaults to `null`. The delegated Azure Resource Id which contains a Managed Identity. This field is only used in cross tenant scenario. Changing this forces a new resource to be created.
    - `skip_service_principal_aad_check`       - (Optional) - Defaults to `false`. If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. 

  Example Inputs:
  ```hcl
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
  DESCRIPTION

  validation {
    condition = alltrue([
      for _, v in var.topics :
      contains(["Active", "Creating", "Deleting", "Disabled", "ReceiveDisabled", "Renaming", "SendDisabled", "Unknown"], v.status)
    ])
    error_message = "The status parameter can only be `Active`, `Creating`, `Deleting`, `Disabled`, `ReceiveDisabled`, `Renaming`, `SendDisabled`, `Unknown`."
  }

  validation {
    condition = alltrue([
      for _, v in var.topics :
      contains([1024, 2048, 3072, 4096, 5120, 10240, 20480, 40960, 81920], v.max_size_in_megabytes)
    ])
    error_message = "The max_size_in_megabytes parameter must be one of `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960`, `81920`."
  }

  validation {
    condition = alltrue(flatten([
      for topicName, topic in var.topics :
      [
        for subscriptionName, subscription in topic.subscriptions :
        1 <= subscription.max_delivery_count && 2147483647 >= subscription.max_delivery_count
      ]
    ]))
    error_message = "value of max_delivery_count of the topic subscription must be between 1 and 2147483647."
  }

  validation {
    condition = alltrue(flatten([
      for topicName, topic in var.topics :
      [
        for subscriptionName, subscription in topic.subscriptions :
        contains(["Active", "Disabled", "ReceiveDisabled"], subscription.status)
      ]
    ]))
    error_message = "value of max_delivery_count of the topic subscription must be between 1 and 2147483647."
  }
}
