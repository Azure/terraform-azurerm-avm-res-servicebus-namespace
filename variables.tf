variable "location" {
  type        = string
  description = <<DESCRIPTION
  Azure region where the resource should be deployed.
  If null, the location will be inferred from the resource group location.
  Changing this forces a new resource to be created.
  
  Example Inputs: eastus
  See more in CLI: az account list-locations -o table --query "[].name"
  DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
  Specifies the name of the ServiceBus Namespace resource. 
  Changing this forces a new resource to be created. 
  Name must only contain letters, numbers, and hyphens and be between 6 and 50 characteres long. Also, it must not start or end with a hyphen.

  Example Inputs: sb-sharepoint-prod-westus-001
  See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftservicebus
  DESCRIPTION
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "The 'name' variable must only contain letters, numbers, and hyphens."
  }
  validation {
    condition     = length(var.name) <= 50 && length(var.name) >= 6
    error_message = "The 'name' variable must be between 6 and 50 characters long"
  }
  validation {
    condition     = substr(var.name, 0, 1) != "-" && substr(var.name, length(var.name) - 1, 1) != "-"
    error_message = "The 'name' variable must not start or end with a hyphen."
  }
}

variable "resource_group_name" {
  type        = string
  description = <<DESCRIPTION
  The name of the resource group in which to create this resource. 
  Changing this forces a new resource to be created.
  Name must be less than 90 characters long and must only contain underscores, hyphens, periods, parentheses, letters, or digits.

  Example Inputs: rg-sharepoint-prod-westus-001
  See more: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftresources
  DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.resource_group_name) <= 90
    error_message = "The 'resource_group_name' variable must be less than 90 characters long."
  }
  validation {
    condition     = can(regex("^[().a-zA-Z0-9_-]+$", var.resource_group_name))
    error_message = "The 'resource_group_name' variable must only contain underscores, hyphens, periods, parentheses, letters, or digits."
  }
}

variable "authorization_rules" {
  type = map(object({
    name   = optional(string, null)
    send   = optional(bool, false)
    listen = optional(bool, false)
    manage = optional(bool, false)
  }))
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. Manages a ServiceBus Namespace authorization Rule within a ServiceBus.

  - `name`   - (Optional) - Defaults to `null`. Specifies the name of the ServiceBus Namespace Authorization Rule resource. Changing this forces a new resource to be created. If it is null it will use the map key as the name.
  - `send`   - (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Listen permissions to the ServiceBus Namespace?
  - `listen` - (Optional) - Always set to `true` when manage is `true` if not it will default to `false`. Does this Authorization Rule have Send permissions to the ServiceBus Namespace? 
  - `manage` - (Optional) - Defaults to `false`. Does this Authorization Rule have Manage permissions to the ServiceBus Namespace?

  Example Inputs:
  ```hcl
  authorization_rules = {
    testRule = {
      send   = true
      listen = true
      manage = true
    }
  }
  ```
  DESCRIPTION
  nullable    = false
}

variable "capacity" {
  type        = number
  default     = null
  description = <<DESCRIPTION
  Always set to `0` for Standard and Basic. Defaults to `1` for Premium. Specifies the capacity. 
  When sku is Premium, capacity can be 1, 2, 4, 8 or 16.
  DESCRIPTION

  validation {
    condition     = var.capacity == null || can(index([1, 2, 4, 8, 16], var.capacity))
    error_message = "The 'capacity' variable must be 1, 2, 4, 8, or 16 when 'sku' is 'Premium'."
  }
}

variable "local_auth_enabled" {
  type        = bool
  default     = true
  description = "Defaults to `true`. Whether or not SAS authentication is enabled for the Service Bus namespace."
  nullable    = false
}

variable "minimum_tls_version" {
  type        = string
  default     = "1.2"
  description = "Defaults to `1.2`. The minimum supported TLS version for this Service Bus Namespace. Valid values are: 1.0, 1.1 and 1.2."
  nullable    = false

  validation {
    condition     = var.minimum_tls_version == null || can(index(["1.0", "1.1", "1.2"], var.minimum_tls_version))
    error_message = "The 'minimum_tls_version' variable must be '1.0', '1.1' or '1.2'."
  }
}

variable "premium_messaging_partitions" {
  type        = number
  default     = null
  description = <<DESCRIPTION
  Always set to `0` for Standard and Basic. Defaults to `1` for Premium. Specifies the number of messaging partitions. 
  Possible values when Premium are 1, 2, and 4. Changing this forces a new resource to be created.
  DESCRIPTION

  validation {
    condition     = var.premium_messaging_partitions == null || can(index([1, 2, 4], var.premium_messaging_partitions))
    error_message = "The 'premium_messaging_partitions' variable must be 1, 2, or 4 when 'sku' is 'Premium'."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Defaults to `true`. Is public network access enabled for the Service Bus Namespace?"
  nullable    = false
}

variable "sku" {
  type        = string
  default     = "Standard"
  description = <<DESCRIPTION
  Defaults to `Standard`. Defines which tier to use. Options are Basic, Standard or Premium. 
  Please note that setting this field to Premium will force the creation of a new resource.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The 'sku' variable must be either 'Basic', 'Standard', or 'Premium'."
  }
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 30 minutes) Used when creating the ServiceBus Namespace.
 - `delete` - (Defaults to 30 minutes) Used when deleting the ServiceBus Namespace.
 - `read` - (Defaults to 5 minutes) Used when retrieving the ServiceBus Namespace.
 - `update` - (Defaults to 30 minutes) Used when updating the ServiceBus Namespace.
EOT  
}

variable "zone_redundant" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
  Always set to `false` for Standard and Basic. Defaults to `true` for Premium. Whether or not this resource is zone redundant. 
  Changing this forces a new resource to be created.
  DESCRIPTION
}
