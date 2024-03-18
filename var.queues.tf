variable "queues" {
  type = map(object({
    lock_duration                           = optional(string, null)
    max_message_size_in_kilobytes           = optional(number, null)
    max_size_in_megabytes                   = optional(number, null)
    requires_duplicate_detection            = optional(bool, null)
    requires_session                        = optional(bool, null)
    default_message_ttl                     = optional(string, null)
    dead_lettering_on_message_expiration    = optional(bool, null)
    duplicate_detection_history_time_window = optional(string, null)
    max_delivery_count                      = optional(number, null)
    status                                  = optional(string, null)
    enable_batched_operations               = optional(bool, null)
    auto_delete_on_idle                     = optional(string, null)
    enable_partitioning                     = optional(bool, null)
    enable_express                          = optional(bool, null)
    forward_to                              = optional(string, null)
    forward_dead_lettered_messages_to       = optional(string, null)

    authorization_rules = optional(map(object({
      send   = optional(bool, null)
      listen = optional(bool, null)
      manage = optional(bool, null)
    })), {})
  }))
  default = {}
  description = "value"
}