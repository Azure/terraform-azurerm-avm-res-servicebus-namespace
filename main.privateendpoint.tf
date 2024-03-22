# The PE resource when we are managing the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this_managed_dns_zone_groups" {
  for_each = var.private_endpoints_manage_dns_zone_group ? { for k, v in var.private_endpoints : k => v } : {}

  name                          = coalesce(each.value.name, "pep-${var.name}")

  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  location                      = coalesce(each.value.location, var.location)
  resource_group_name           = coalesce(each.value.resource_group_name, var.resource_group_name)
  tags                          = each.value.tags == null ? {} : each.value.tags == {} ? var.tags : each.value.tags

  private_service_connection {
    name                           = coalesce(each.value.private_service_connection_name, "pse-${var.name}")

    is_manual_connection           = false
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    subresource_names              = ["namespace"] # map to each.value.subresource_name if there are multiple services.
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      subresource_name   = local.service_name # map to each.value.subresource_name if there are multiple services.
      member_name        = local.service_name # map to each.value.subresource_name if there are multiple services.
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = var.private_endpoints_manage_dns_zone_group == false ? { for k, v in var.private_endpoints : k => v } : {}

  name                          = coalesce(each.value.name, "pep-${var.name}")

  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  location                      = coalesce(each.value.location, var.location)
  resource_group_name           = coalesce(each.value.resource_group_name, var.resource_group_name)
  tags                          = each.value.tags == null ? {} : each.value.tags == {} ? var.tags : each.value.tags

  private_service_connection {
    name                           = coalesce(each.value.private_service_connection_name, "pse-${var.name}")

    is_manual_connection           = false
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    subresource_names              = [local.service_name] # map to each.value.subresource_name if there are multiple services.
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name

      subresource_name   = local.service_name # map to each.value.subresource_name if there are multiple services.
      member_name        = local.service_name # map to each.value.subresource_name if there are multiple services.
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each                      = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = azurerm_private_endpoint.this_managed_dns_zone_groups[each.value.pe_key].id
}