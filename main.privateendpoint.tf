# The private endpoints are split across two resources because each one is the destination of a `moved`
# block from its AzureRM counterpart, and Terraform allows only one source per destination. The two are
# configured identically: the private DNS zone group is a separate child resource in AzAPI, so the
# private endpoint itself no longer differs between the modes.

# The private endpoints when the module manages their private DNS zone groups.
resource "azapi_resource" "private_endpoints" {
  for_each = { for key, endpoint in local.private_endpoints : key => endpoint if var.private_endpoints_manage_dns_zone_group }

  location               = each.value.location
  name                   = each.value.name
  parent_id              = each.value.parent_id
  type                   = "Microsoft.Network/privateEndpoints@2024-05-01"
  body                   = each.value.body
  response_export_values = ["properties.customDnsConfigs", "properties.networkInterfaces"]
  tags                   = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_private_endpoint.this_managed_dns_zone_groups
  to   = azapi_resource.private_endpoints
}

# The private endpoints when their private DNS zone groups are managed elsewhere, for example by Azure
# Policy.
resource "azapi_resource" "private_endpoints_unmanaged_dns_zone_groups" {
  for_each = { for key, endpoint in local.private_endpoints : key => endpoint if !var.private_endpoints_manage_dns_zone_group }

  location               = each.value.location
  name                   = each.value.name
  parent_id              = each.value.parent_id
  type                   = "Microsoft.Network/privateEndpoints@2024-05-01"
  body                   = each.value.body
  response_export_values = ["properties.customDnsConfigs", "properties.networkInterfaces"]
  tags                   = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoints_unmanaged_dns_zone_groups
}

# Application security groups are part of the private endpoint's body from this version. The
# association resources the AzureRM provider used are dropped from the state without being deleted, so
# the private endpoints keep their application security groups.
removed {
  from = azurerm_private_endpoint_application_security_group_association.this

  lifecycle {
    destroy = false
  }
}

# The AzureRM provider managed the private DNS zone group inside the private endpoint. Here it is a
# child resource; on upgrade it is written again with the same name and zones, which leaves it unchanged.
resource "azapi_resource" "private_dns_zone_groups" {
  for_each = { for key, endpoint in local.normalized_private_endpoints : key => endpoint if var.private_endpoints_manage_dns_zone_group && length(endpoint.private_dns_zone_resource_ids) > 0 }

  name      = each.value.private_dns_zone_group_name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01"
  body = {
    properties = {
      # Each configuration is named after its zone, as the AzureRM provider named them.
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in each.value.private_dns_zone_resource_ids : {
          name = provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", private_dns_zone_resource_id).name
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    }
  }
  response_export_values = []

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# The AzureRM provider read each private endpoint's private IP address from its network interface. The
# private endpoint reports the address itself only when it is not linked to a private DNS zone, so the
# network interface is read here as well.
data "azapi_resource" "private_endpoint_network_interfaces" {
  for_each = local.private_endpoint_resources

  resource_id = each.value.output.properties.networkInterfaces[0].id
  type        = "Microsoft.Network/networkInterfaces@2024-05-01"
  response_export_values = {
    private_ip_address = "properties.ipConfigurations[0].properties.privateIPAddress"
  }
}
