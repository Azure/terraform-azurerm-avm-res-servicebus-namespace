variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  nullable    = false
  
  description = <<DESCRIPTION
    A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

    map(
      object({
        role_definition_id_or_name             = Required - The ID or name of the role definition to assign to the principal.
        principal_id                           = Required - It's a GUID - The ID of the principal to assign the role to. 
        description                            = Optional - Defaults to null. The description of the role assignment.
        condition                              = Optional - Defaults to null. The condition which will be used to scope the role assignment.
        condition_version                      = Optional - Defaults to null. The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
        delegated_managed_identity_resource_id = Optional - Defaults to null. The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
        skip_service_principal_aad_check       = Optional - Defaults to false. If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. 
      })
    )

    > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

    Example Inputs:
    ```terraform
    role_assignments = {
      "key" = {
        condition_version                = "2.0"
        skip_service_principal_aad_check = false
        role_definition_id_or_name       = "Contributor"
        description                      = "This is a test role assignment"
        principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
        condition                        = "@resource.name == 'sb-namespace'"
      }
    }
    ```
  DESCRIPTION

  validation {
    condition     = alltrue([for k, v in var.role_assignments : role_definition_id_or_name != null ])
    error_message = "principal_id must be a valid GUID"
  }

  validation {
    condition     = alltrue([for k, v in var.role_assignments : can(regex("^([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})$", v.principal_id)) ])
    error_message = "principal_id must be a valid GUID"
  }

  validation {
    condition = alltrue([for k, v in var.role_assignments : contains(["2.0", null], v.condition_version)])
    error_message = "condition_version must be '2.0' or null"
  }
}