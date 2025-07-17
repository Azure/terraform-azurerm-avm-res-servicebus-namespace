variable "customer_managed_key" {
  type = object({
    key_name              = string
    key_vault_resource_id = string

    key_version = optional(string, null)

    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
  Defaults to `null`. Ignored for Basic and Standard. Defines a customer managed key to use for encryption.

  - `key_name`               - (Required) - The key name for the customer managed key in the key vault.
  - `key_vault_resource_id`  - (Required) - The full Azure Resource ID of the key_vault where the customer managed key will be referenced from.
  - `key_version`            - (Optional) - Defaults to `null`. The version of the key to use if it is null it will use the latest version of the key. It will also auto rotate when the key in the key vault is rotated.

  - `user_assigned_identity` - (Required) - The user assigned identity to use when access the key vault
    - `resource_id`          - (Required) - The full Azure Resource ID of the user assigned identity.

  > Note: Remember to assign permission to the managed identity to access the key vault key. The Key vault used must have enabled soft delete and purge protection. The minimun required permissions is "Key Vault Crypto Service Encryption User"
  > Note: If you require to control "infrastructure encryption" use the parameter `infrastructure_encryption_enabled` in the module configuration.

  Example Inputs:
  ```hcl
  customer_managed_key = {
    key_name               = "sample-customer-key"
    key_version            = 03c89971825b4a0d84905c3597512260
    key_vault_resource_id  = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}"
    
    user_assigned_identity {
      resource_id = "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}"
    }
  }
  ```
  DESCRIPTION

  validation {
    condition     = var.customer_managed_key == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/.+$", var.customer_managed_key.user_assigned_identity.resource_id))
    error_message = "'user_assigned_identity.resource_id' must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{managedIdentityName}'"
  }
  validation {
    condition     = var.customer_managed_key == null || can(regex("^/subscriptions/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/resourceGroups/.+/providers/Microsoft.KeyVault/vaults/.+$", var.customer_managed_key.key_vault_resource_id))
    error_message = "'key_vault_resource_id' must be in the format '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{keyVaultName}'"
  }
  validation {
    condition     = var.customer_managed_key == null ? true : var.customer_managed_key.key_name != null
    error_message = "'key_name' must have a value"
  }
}

variable "infrastructure_encryption_enabled" {
  type        = bool
  default     = true
  description = "Defaults to `true`. Used to specify whether enable Infrastructure Encryption (Double Encryption). Changing this forces a new resource to be created. Requires `customer_managed_key`."
  nullable    = false
}
