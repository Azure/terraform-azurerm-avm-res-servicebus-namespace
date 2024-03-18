resource "azurerm_management_lock" "namespace" {
  count = var.lock != null ? 1 : 0

  scope      = azurerm_servicebus_namespace.this.id

  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")

  lock_level = var.lock.kind
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}