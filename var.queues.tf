variable "queues" {
  type = map(object({
    lock_duration                           = optional(string, null)
    max_message_size_in_kilobytes           = optional(number, null)
    max_size_in_megabytes                   = optional(number, 1024)
    requires_duplicate_detection            = optional(bool, false)
    requires_session                        = optional(bool, false)
    default_message_ttl                     = optional(string, null)
    dead_lettering_on_message_expiration    = optional(bool, false)
    duplicate_detection_history_time_window = optional(string, null)
    max_delivery_count                      = optional(number, 10)
    status                                  = optional(string, null)
    enable_batched_operations               = optional(bool, true)
    auto_delete_on_idle                     = optional(string, null)
    enable_partitioning                     = optional(bool, false)
    enable_express                          = optional(bool, false)
    forward_to                              = optional(string, null)
    forward_dead_lettered_messages_to       = optional(string, null)

    authorization_rules = optional(map(object({
      send   = optional(bool, false)
      listen = optional(bool, false)
      manage = optional(bool, false)
    })), {})
  }))
  default = {}
  description = "value"
}