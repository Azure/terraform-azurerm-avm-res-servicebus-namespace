locals {
  normalized_private_endpoints = var.sku == local.premium_sku_name ? var.private_endpoints : {}
  private_endpoint_application_security_group_associations = var.sku == local.premium_sku_name ? {
    for assoc in flatten([
      for pe_k, pe_v in var.private_endpoints : [
        for asg_k, asg_v in pe_v.application_security_group_associations : {
          asg_key         = asg_k
          pe_key          = pe_k
          asg_resource_id = asg_v
        }
      ]
    ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc
  } : {}
  # Every private endpoint, whichever of the two resources in main.privateendpoint.tf manages it.
  private_endpoint_resources = merge(azapi_resource.private_endpoints, azapi_resource.private_endpoints_unmanaged_dns_zone_groups)
  # The configuration of each private endpoint. It reproduces what the AzureRM provider sent, so that
  # upgrading moves the existing private endpoints without changing them.
  private_endpoints = {
    for key, endpoint in local.normalized_private_endpoints : key => {
      body = {
        properties = merge(
          {
            # Empty lists are sent rather than omitted, so that removing the last application security
            # group or IP configuration removes it from Azure.
            applicationSecurityGroups = [
              for asg_resource_id in values(endpoint.application_security_group_associations) : { id = asg_resource_id }
            ]
            ipConfigurations = [
              for ip_configuration in values(endpoint.ip_configurations) : {
                name = ip_configuration.name
                properties = {
                  groupId          = coalesce(endpoint.subresource_name, local.service_name)
                  memberName       = coalesce(ip_configuration.member_name, local.service_name)
                  privateIPAddress = ip_configuration.private_ip_address
                }
              }
            ]
            privateLinkServiceConnections = [
              {
                name = coalesce(endpoint.private_service_connection_name, "pse-${var.name}")
                properties = {
                  groupIds             = [coalesce(endpoint.subresource_name, local.service_name)]
                  privateLinkServiceId = azurerm_servicebus_namespace.this.id
                }
              }
            ]
            subnet = {
              id = endpoint.subnet_resource_id
            }
          },
          # Azure stores an unset custom network interface name as an empty string, so the property is
          # sent only when it is set. Sending null would report a difference on every plan.
          endpoint.network_interface_name == null ? {} : { customNetworkInterfaceName = endpoint.network_interface_name },
        )
      }
      location = coalesce(endpoint.location, var.location)
      name     = coalesce(endpoint.name, "pep-${var.name}")
      # `resource_group_name` is a resource group in the namespace's subscription, as it was with the
      # AzureRM provider.
      parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${coalesce(endpoint.resource_group_name, var.resource_group_name)}"
      tags      = endpoint.tags == null ? var.tags : endpoint.tags
    }
  }
  service_name = "namespace"
}
