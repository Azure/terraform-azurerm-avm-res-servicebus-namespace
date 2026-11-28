mock_provider "azurerm" {
  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    }
  }
}

mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateEndpoints/pep-test-namespace"
      output = {
        properties = {
          customDnsConfigs  = []
          networkInterfaces = [{ id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/networkInterfaces/nic" }]
        }
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
    }
  }
  mock_data "azapi_resource" {
    defaults = {
      output = {
        private_ip_address = "10.0.0.4"
      }
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  enable_telemetry    = false
  name                = "test-namespace"
  location            = "westeurope"
  resource_group_name = "test"
  sku                 = "Premium"
}

run "body_reproduces_the_azurerm_request" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/pe"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"]
        application_security_group_associations = {
          asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/applicationSecurityGroups/asg"
        }
        ip_configurations = {
          static = {
            name               = "static"
            private_ip_address = "10.0.0.6"
          }
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.private_endpoints["endpoint"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test" && azapi_resource.private_endpoints["endpoint"].name == "pep-test-namespace"
    error_message = "The private endpoint MUST default to the namespace resource group and the pep-<name> name."
  }

  assert {
    condition     = jsonencode(azapi_resource.private_endpoints["endpoint"].body.properties.applicationSecurityGroups) == jsonencode([{ id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/applicationSecurityGroups/asg" }])
    error_message = "Application security groups MUST be part of the private endpoint body."
  }

  assert {
    condition     = jsonencode(azapi_resource.private_endpoints["endpoint"].body.properties.ipConfigurations) == jsonencode([{ name = "static", properties = { groupId = "namespace", memberName = "namespace", privateIPAddress = "10.0.0.6" } }])
    error_message = "IP configurations MUST default the group and member to namespace."
  }

  assert {
    condition     = !contains(keys(azapi_resource.private_endpoints["endpoint"].body.properties), "customNetworkInterfaceName")
    error_message = "An unset custom network interface name MUST NOT be sent."
  }

  assert {
    condition     = azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].properties.privateLinkServiceId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    error_message = "The private link connection MUST target the namespace."
  }

  assert {
    condition     = azapi_resource.private_dns_zone_groups["endpoint"].name == "default" && jsonencode(azapi_resource.private_dns_zone_groups["endpoint"].body.properties.privateDnsZoneConfigs) == jsonencode([{ name = "privatelink.servicebus.windows.net", properties = { privateDnsZoneId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net" } }])
    error_message = "The DNS zone group MUST keep the azurerm name and name each configuration after its zone."
  }

  assert {
    condition     = output.resource_private_endpoints["endpoint"].private_service_connection[0].private_ip_address == "10.0.0.4"
    error_message = "The private IP address MUST be read from the network interface."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "no_dns_zone_group_without_zones" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/pe"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.private_dns_zone_groups) == 0 && jsonencode(azapi_resource.private_endpoints["endpoint"].body.properties.applicationSecurityGroups) == "[]"
    error_message = "No DNS zone group MUST be created without zones, and an empty application security group list MUST be sent."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "standard_creates_no_private_endpoints" {
  command = plan

  variables {
    sku = "Standard"
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/pe"
      }
    }
  }

  assert {
    condition     = length(azapi_resource.private_endpoints) == 0 && length(azapi_resource.private_dns_zone_groups) == 0
    error_message = "Private endpoints MUST only be created for Premium namespaces."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}
