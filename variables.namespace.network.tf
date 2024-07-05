variable "network_rule_config" {
  type = object({
    trusted_services_allowed = optional(bool, false)
    cidr_or_ip_rules         = optional(set(string), [])
    default_action           = optional(string, "Allow")

    network_rules = optional(set(object({
      subnet_id = string
    })), [])
  })
  nullable    = false
  default     = {}
  description = <<DESCRIPTION
  Defaults to `{}`. IP rules only for Basic and Standard, virtual network or IP rules for Premium. Defines the network rules configuration for the resource.

  - `trusted_services_allowed` - (Optional) - Defaults to `false`. Are Azure Services that are known and trusted for this resource type are allowed to bypass firewall configuration? 
  - `cidr_or_ip_rules`         - (Optional) - Defaults to `[]`. One or more IP Addresses, or CIDR Blocks which should be able to access the ServiceBus Namespace.
  - `default_action`           - (Optional) - Defaults to `Allow`. Specifies the default action for the Network Rule Set when a rule (IP, CIDR or subnet) doesn't match. Possible values are `Allow` and `Deny`.

  - `network_rules` - (Optional) - Defaults to `[]`. Ignored for Basic and Standard.
    - `subnet_id` - (Required) - The Subnet ID which should be able to access this ServiceBus Namespace.

  > Note: Remember to enable Microsoft.ServiceBus service endpoint on the subnet.

  Example Inputs:
  ```hcl
  network_rule_config = {
    trusted_services_allowed = true
    default_action           = "Allow"
    cidr_or_ip_rules         = ["79.0.0.0", "80.0.0.0/24"]

    network_rules = [
      {
        subnet_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}"
      }
    ]
  }
  ```
  DESCRIPTION

  validation {
    condition     = contains(["Allow", "Deny"], var.network_rule_config.default_action)
    error_message = "'default_action' can only be 'Allow' or 'Deny'"
  }

  validation {
    condition = alltrue([
      for value in var.network_rule_config.network_rules :
      can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", value.subnet_id))
    ])
    error_message = "'network_rules' must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}'"
  }

  validation {
    condition = alltrue([
      for value in var.network_rule_config.cidr_or_ip_rules :
      value == null ? false : strcontains(value, "/") == false || can(cidrhost(value, 0))
    ])
    error_message = "Allowed Ips must be valid IPv4 CIDR."
  }

  validation {
    condition = alltrue([
      for value in var.network_rule_config.cidr_or_ip_rules :
      value == null ? false : strcontains(value, "/") || can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", value))
    ])
    error_message = "Allowed IPs must be valid IPv4."
  }
}