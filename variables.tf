variable "name" {
  type        = string
  description = <<DESCRIPTION
    Specifies the name of the ServiceBus Namespace resource. 
    Changing this forces a new resource to be created. 
    Name must only contain letters, numbers, and hyphens and be between 6 and 50 characteres long.
    name variable must not start or end with a hyphen.
  DESCRIPTION

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name)) && length(var.name) <= 50 && length(var.name) >= 6 && substr(var.name, 0, 1) != "-" && substr(var.name, length(var.name)-1, 1) != "-"
    error_message = "The name variable must only contain letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.name) <= 50 && length(var.name) >= 6
    error_message = "The name variable must be between 6 and 50 characters long"
  }

  validation {
    condition     = substr(var.name, 0, 1) != "-" && substr(var.name, length(var.name)-1, 1) != "-"
    error_message = "The name variable must not start or end with a hyphen."
  }
}

variable "resource_group_name" {
  type        = string
  description = <<DESCRIPTION
    The name of the resource group in which to create this resource. 
    Changing this forces a new resource to be created.
    Name must be less than 90 characters long and must only contain underscores, hyphens, periods, parentheses, letters, or digits.
  DESCRIPTION

  validation {
    condition     = length(var.resource_group_name) <= 90
    error_message = "The resource_group_name variable must be less than 90 characters long."
  }

  validation {
    condition     = can(regex("^[().a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The resource_group_name variable must only contain underscores, hyphens, periods, parentheses, letters, or digits."
  }
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "sku" {
  type        = string
  nullable    = false
  default     = "Standard"
  description = <<DESCRIPTION
    Defaults to Standard. Defines which tier to use. Options are Basic, Standard or Premium. 
    Please note that setting this field to Premium will force the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = can(index(["Basic", "Standard", "Premium"], var.sku))
    error_message = "The sku variable must be either Basic, Standard, or Premium."
  }
}

variable "capacity" {
  type        = number
  default     = null
  description = <<DESCRIPTION
    Ignored for Standard and Basic. Defaults to 1 for Premium. Specifies the capacity. 
    When sku is Premium, capacity can be 1, 2, 4, 8 or 16.
  DESCRIPTION

  validation {
    condition     = var.capacity == null || can(index([1, 2, 4, 8, 16], var.capacity))
    error_message = "The capacity variable must be 1, 2, 4, 8, or 16 when sku is Premium."
  }
}

variable "premium_messaging_partitions" {
  type        = number
  default     = null
  description = <<DESCRIPTION
    Ignored for Standard and Basic. Defaults to 1 for Premium. Specifies the number messaging partitions. 
    Only valid when sku is Premium and the minimum number is 1. 
    Possible values include 1, 2, and 4. Changing this forces a new resource to be created.
  DESCRIPTION

  validation {
    condition     = var.premium_messaging_partitions == null || can(index([1, 2, 4], var.premium_messaging_partitions))
    error_message = "The premium_messaging_partitions variable must be 1, 2, or 4 when sku is Premium."
  }
}

variable "zone_redundant" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
    Ignored for Standard and Basic. Defaults to true for Premium. Whether or not this resource is zone redundant. 
    sku needs to be Premium. Changing this forces a new resource to be created.
  DESCRIPTION
}

variable "local_auth_enabled" {
  type        = bool
  nullable    = false
  default     = true
  description = "Defaults to true. Whether or not SAS authentication is enabled for the Service Bus namespace."
}

variable "public_network_access_enabled" {
  type        = bool
  nullable    = false
  default     = true
  description = "Defaults to true. Is public network access enabled for the Service Bus Namespace?"
}

variable "minimum_tls_version" {
  type        = string
  nullable    = false
  default     = "1.2"
  description = "Defaults to 1.2. The minimum supported TLS version for this Service Bus Namespace. Valid values are: 1.0, 1.1 and 1.2."
  
  validation {
    condition     = var.minimum_tls_version == null || can(index(["1.0", "1.1", "1.2"], var.minimum_tls_version))
    error_message = "The minimum_tls_version variable must be 1.0, 1.1 or 1.2."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
    Controls the Managed Identity configuration on this resource. The following properties can be specified:

    - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
    - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
}

variable "customer_managed_key" {
  type = object({
    key_vault_key_id                  = string
    user_mi_id_to_access_key          = string
    infrastructure_encryption_enabled = optional(bool, true)
  })

  default     = null
  description = "Remember to assign permission to the managed identity to access the key vault key. The Key vault used must have enabled soft delete and purge protection"
}

variable "network_rule_config" {
  type = object({
    trusted_services_allowed      = optional(bool, false)
    cidr_or_ip_rules              = optional(set(string), [])
    default_action                = optional(string, "Allow")

    network_rules = optional(set(object({
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })), [])
  })

  nullable    = false
  default     = {}
  description = ""
}

variable "tags" {
  type     = map(string)
  default  = {}
  nullable = false
}