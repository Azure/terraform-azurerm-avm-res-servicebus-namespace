mock_provider "azurerm" {
  alias = "mock"

  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    }
  }
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateEndpoints/test-endpoint"
    }
  }
  mock_resource "azurerm_servicebus_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/queues/test-queue"
    }
  }
  mock_resource "azurerm_servicebus_topic" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/topics/test-topic"
    }
  }
}

mock_provider "azapi" {
  alias = "mock"
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name                = "test-namespace"
  location            = "westeurope"
  resource_group_name = "test"
  private_endpoints = {
    endpoint = {
      name                            = "explicit-endpoint"
      subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
      subresource_name                = "namespace"
      private_dns_zone_group_name     = "explicit-dns"
      private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net"]
      private_service_connection_name = "explicit-connection"
      network_interface_name          = "explicit-nic"
      location                        = "eastus"
      resource_group_name             = "endpoint-group"
      tags                            = { endpoint = "true" }
      ip_configurations = {
        static = {
          name               = "static"
          private_ip_address = "10.0.0.6"
          member_name        = "namespace"
        }
      }
      application_security_group_associations = {
        asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/applicationSecurityGroups/test"
      }
      role_assignments = {
        contributor = {
          name                             = "00000000-0000-0000-0000-000000000001"
          role_definition_id_or_name       = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
          principal_id                     = "00000000-0000-0000-0000-000000000002"
          description                      = "Endpoint permission"
          principal_type                   = "ServicePrincipal"
          skip_service_principal_aad_check = true
          condition                        = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:Name] StringEquals 'example'"
          condition_version                = "2.0"
        }
      }
      lock = {
        name  = "endpoint-lock"
        kind  = "CanNotDelete"
        notes = "Endpoint protection"
      }
    }
  }
}

run "managed_explicit_fields" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    enable_telemetry = null
  }

  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 1 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].name == "explicit-endpoint" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].location == "eastus" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].resource_group_name == "endpoint-group" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].custom_network_interface_name == "explicit-nic" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].tags["endpoint"] == "true" &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection).name == "explicit-connection" &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection).private_connection_resource_id == output.resource_id &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection).subresource_names == tolist(["namespace"]) &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration).member_name == "namespace" &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration).private_ip_address == "10.0.0.6" &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_dns_zone_group).name == "explicit-dns"
    )
    error_message = "The managed endpoint must preserve its address and apply all connection, IP, DNS, location and tag settings."
  }
  assert {
    condition = (
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].name == "00000000-0000-0000-0000-000000000001" &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].principal_id == "00000000-0000-0000-0000-000000000002" &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].description == "Endpoint permission" &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].principal_type == "ServicePrincipal" &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].condition_version == "2.0" &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].condition == var.private_endpoints["endpoint"].role_assignments["contributor"].condition &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].role_definition_id == var.private_endpoints["endpoint"].role_assignments["contributor"].role_definition_id_or_name &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].skip_service_principal_aad_check &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].scope == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id &&
      azurerm_management_lock.this["PrivateEndpoint|endpoint"].notes == "Endpoint protection" &&
      azurerm_management_lock.this["PrivateEndpoint|endpoint"].scope == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id &&
      azurerm_private_endpoint_application_security_group_association.this["endpoint-asg"].private_endpoint_id == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id
    )
    error_message = "Existing endpoint role assignment, lock and association addresses and scope must be preserved with supplied fields applied."
  }
  assert {
    condition     = var.enable_telemetry && length(azapi_resource.telemetry) == 1
    error_message = "Telemetry remains enabled by default and is exercised only through its mock."
  }
}

run "unmanaged_explicit_fields" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints_manage_dns_zone_group = false
  }
  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1 &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].name == "explicit-endpoint" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].location == "eastus" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].resource_group_name == "endpoint-group" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].custom_network_interface_name == "explicit-nic" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].tags["endpoint"] == "true" &&
      one(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_service_connection).subresource_names == tolist(["namespace"]) &&
      one(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_service_connection).private_connection_resource_id == output.resource_id &&
      one(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration).member_name == "namespace" &&
      one(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration).private_ip_address == "10.0.0.6" &&
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_dns_zone_group) == 0 &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].scope == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id &&
      azurerm_role_assignment.this["PrivateEndpoint|contributor"].condition_version == "2.0" &&
      azurerm_management_lock.this["PrivateEndpoint|endpoint"].scope == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id &&
      azurerm_management_lock.this["PrivateEndpoint|endpoint"].notes == "Endpoint protection" &&
      azurerm_private_endpoint_application_security_group_association.this["endpoint-asg"].private_endpoint_id == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id
    )
    error_message = "DNS-off mode must use only the existing unmanaged endpoint address and preserve extension scope and IP settings."
  }
}

run "omitted_fields_and_inherited_lock" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    tags = { inherited = "true" }
    lock = { kind = "CanNotDelete" }
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
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
    condition = (
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].name == "pep-test-namespace" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].location == var.location &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].resource_group_name == var.resource_group_name &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].tags["inherited"] == "true" &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection).name == "pse-test-namespace" &&
      one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration).member_name == "namespace" &&
      length(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_dns_zone_group) == 0 &&
      azurerm_management_lock.this["PrivateEndpoint|endpoint"].notes == "Cannot delete the resource or its child resources." &&
      length(azurerm_role_assignment.this) == 0
    )
    error_message = "Existing endpoint defaults, tag and lock inheritance must remain unchanged."
  }
}

run "basic_ignores_endpoints" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    sku = "Basic"
  }
  assert {
    condition = (
      length(output.resource_private_endpoints) == 0 &&
      length(azurerm_private_endpoint_application_security_group_association.this) == 0 &&
      length(azurerm_role_assignment.this) == 0 &&
      length(azurerm_management_lock.this) == 0
    )
    error_message = "Basic namespaces must continue to ignore endpoints and their extensions."
  }
}

run "standard_ignores_endpoints_and_telemetry_opt_out" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    sku              = "Standard"
    enable_telemetry = false
  }
  assert {
    condition = (
      length(output.resource_private_endpoints) == 0 &&
      length(azurerm_private_endpoint_application_security_group_association.this) == 0 &&
      length(azurerm_role_assignment.this) == 0 &&
      length(azurerm_management_lock.this) == 0 &&
      length(azapi_resource.telemetry) == 0
    )
    error_message = "Standard namespaces must continue to ignore endpoints and retain the telemetry opt-out."
  }
}

run "invalid_subresource" {
  command = plan
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        subresource_name   = "unsupported"
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_member" {
  command = plan
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        ip_configurations = {
          static = {
            name               = "static"
            private_ip_address = "10.0.0.6"
            member_name        = "unsupported"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_subnet" {
  command = plan
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {
      endpoint = { subnet_resource_id = "not-a-subnet-id" }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone" {
  command = plan
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        private_dns_zone_resource_ids = ["not-a-zone-id"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_application_security_group" {
  command = plan
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        application_security_group_associations = { asg = "not-an-asg-id" }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity" {
  command = plan
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        role_assignments = {
          invalid = {
            role_definition_id_or_name             = "Contributor"
            principal_id                           = "00000000-0000-0000-0000-000000000002"
            delegated_managed_identity_resource_id = "not-an-identity-id"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "legacy_child_role_assignment_shapes" {
  command = apply
  providers = {
    azurerm = azurerm.mock
    azapi   = azapi.mock


  }
  variables {
    private_endpoints = {}
    queues = {
      queue = {
        role_assignments = {
          contributor = {
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
            principal_id               = "00000000-0000-0000-0000-000000000002"
          }
        }
      }
    }
    topics = {
      topic = {
        role_assignments = {
          contributor = {
            role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
            principal_id               = "00000000-0000-0000-0000-000000000002"
          }
        }
      }
    }
  }
  assert {
    condition = (
      length(azurerm_role_assignment.this) == 2 &&
      azurerm_role_assignment.this["Queue|contributor|queue"].scope == azurerm_servicebus_queue.base_queues["queue"].id &&
      azurerm_role_assignment.this["Topic|contributor|topic"].scope == azurerm_servicebus_topic.this["topic"].id &&
      azurerm_role_assignment.this["Queue|contributor|queue"].principal_id == "00000000-0000-0000-0000-000000000002" &&
      azurerm_role_assignment.this["Topic|contributor|topic"].principal_id == "00000000-0000-0000-0000-000000000002"
    )
    error_message = "Queue and topic role assignments must retain their existing input shapes, addresses and scope."
  }
}
