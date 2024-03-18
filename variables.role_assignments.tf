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
        delegated_managed_identity_resource_id = optional(string)
        skip_service_principal_aad_check       = Optional - Defaults to false. If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. 
      })
    )

    > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

    Example Inputs:
    ```terraform
    role_assignments = {
      "key" = {
        role_definition_id_or_name       = "Contributor"
        description                      = "This is a test role assignment"
        condition                        = ""
        condition_version                = "2.0"
        skip_service_principal_aad_check = false
        principal_id                     = "eb5260bd-41f3-4019-9e03-606a617aec13"
      }
    }
    ```
  DESCRIPTION
}