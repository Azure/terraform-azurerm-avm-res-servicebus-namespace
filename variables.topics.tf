variable "topics" {
  type = map(object({
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
  }))
  default = {}
    description = <<DESCRIPTION
    Defaults to `{}`. Ignored for Basic. A map of topics to create. The map key is used as the name of the topic.

    map(
      object({
        max_message_size_in_kilobytes            = (Optional) - Always set to `256` for Standard and Basic by Azure. It's mininum and also defaults is `1024` with maximum value of `102400` for Premium. Integer value which controls the maximum size of a message allowed on the Topic.
        max_size_in_megabytes                    = (Optional) - Defaults to `1024`. Possible values are `1024`, `2048`, `3072`, `4096`, `5120`, `10240`, `20480`, `40960` and `81920`. Integer value which controls the size of memory allocated for the Topic.
        requires_duplicate_detection             = (Optional) - Defaults to `false`. Boolean flag which controls whether the Topic requires duplicate detection. Changing this forces a new resource to be created.
        default_message_ttl                      = (Optional) - Defaults to `null`. Mininum value of `PT5S` (5 seconds) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the TTL of messages sent to this topic. This is the default value used when TTL is not set on message itself.
        duplicate_detection_history_time_window  = (Optional) - Defaults to `PT10M` (10 minutes). Minimun of `PT20S` (seconds) and Maximun of `P7D` (7 days). The ISO 8601 timespan duration during which duplicates can be detected.
        status                                   = (Optional) - Defaults to `Active`. The status of the Topic. Possible values are Active, Creating, Deleting, Disabled, ReceiveDisabled, Renaming, SendDisabled, Unknown.
        enable_batched_operations                = (Optional) - Defaults to `true`. Boolean flag which controls whether server-side batched operations are enabled.
        auto_delete_on_idle                      = (Optional) - Defaults to `null`. Minimum of `PT5M` (5 minutes) and maximum of `P10675198D` (10675198 days). Set `null` for never. The ISO 8601 timespan duration of the idle interval after which the Topic is automatically deleted.
        enable_partitioning                      = (Optional) - Defaults to `false` for Basic and Standard. For Premium if premium_messaging_partitions is greater than `1` it will always be set to true if not it will be set to `false`. Boolean flag which controls whether to enable the topic to be partitioned across multiple message brokers. Changing this forces a new resource to be created. 
        enable_express                           = (Optional) - Defaults to `false` for Basic and Standard. Always set to `false` for Premium. Boolean flag which controls whether Express Entities are enabled. An express topic holds a message in memory temporarily before writing it to persistent storage.
        support_ordering                         = (Optional) - Defaults to `false`. Boolean flag which controls whether the Topic supports ordering.

        authorization_rules = map(object({
          send   = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Topic?
          listen = (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Topic? 
          manage = (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Topic?
        }))
      })
    )

    Example Inputs:
    ```terraform
    topics = {
      testTopic = {
        auto_delete_on_idle                     = "PT50M"
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
}