variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
    Controls the Resource Lock configuration for this resource. The following properties can be specified:

    object({
      kind = Required - The type of lock. Possible values are `CanNotDelete` and `ReadOnly`.
      name = Optional. The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
    })

    Example Inputs:
    ```terraform
    lock = {
      kind = "CanNotDelete"
      name = "This resource cannot be deleted easily"
    }
    ```
  DESCRIPTION

  validation {
    condition     = var.lock == null ? true : var.lock.kind == null ? false : contains(["CanNotDelete", "ReadOnly"], var.lock.kind)
    error_message = "Lock kind must be either `CanNotDelete` or `ReadOnly`."
  }
}