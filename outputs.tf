  output "private_endpoints" {
    value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
    description = <<DESCRIPTION
      A map of the private endpoints created.
    DESCRIPTION
  }