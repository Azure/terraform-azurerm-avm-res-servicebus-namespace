<!-- BEGIN_TF_DOCS -->
# Private endpoint example

This deploys the module without public network access and multiple private endpoints combinations

```hcl
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  prefix = "pe"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"

  recommended_regions_only = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_resource_group" "example" {
  name     = "${module.naming.resource_group.name_unique}-${local.prefix}"
  location = module.regions.regions[random_integer.region_index.result].name
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.1.4"

  virtual_network_address_space = ["10.0.0.0/16"]
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  name                          = "${module.naming.virtual_network.name_unique}-${local.prefix}"

  subnets = {
    default = {
      address_prefixes = ["10.0.0.0/24"]
    }
  }
}

module "private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.1.1"

  domain_name         = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.example.name

  virtual_network_links = {
    vnet = {
      vnetlinkname = "vnet-link"
      vnetid       = module.vnet.vnet_resource.id
    }
  }
}

resource "azurerm_application_security_group" "example" {
  name                = "tf-appsecuritygroup-${local.prefix}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "servicebus" {
  source = "../../"

  sku                           = "Premium"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  name                          = "${module.naming.servicebus_namespace.name_unique}-${local.prefix}"
  public_network_access_enabled = false

  private_endpoints = {
    max = {
      name                        = "max"
      private_dns_zone_group_name = "max_group"
      subnet_resource_id          = module.vnet.subnets.default.id

      role_assignments = {
        key = {
          role_definition_id_or_name = "Contributor"
          description                = "This is a test role assignment"
          principal_id               = data.azurerm_client_config.current.object_id
        }
      }

      lock = {
        kind = "CanNotDelete"
        name = "Testing name CanNotDelete"
      }

      tags = {
        environment = "testing"
        department  = "engineering"
      }

      application_security_group_associations = {
        asg1 = azurerm_application_security_group.example.id
      }
    }

    staticIp = {
      name                   = "staticIp"
      network_interface_name = "nic1"
      subnet_resource_id     = module.vnet.subnets.default.id

      ip_configurations = {
        ipconfig1 = {
          name               = "ipconfig1"
          private_ip_address = "10.0.0.7"
        }
      }
    }

    noDnsGroup = {
      name               = "noDnsGroup"
      subnet_resource_id = module.vnet.subnets.default.id
    }

    withDnsGroup = {
      name                        = "withDnsGroup"
      private_dns_zone_group_name = "withDnsGroup_group"

      subnet_resource_id            = module.vnet.subnets.default.id
      private_dns_zone_resource_ids = [module.private_dns_zone.private_dnz_zone_output.id]
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

No requirements.

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm)

- <a name="provider_random"></a> [random](#provider\_random)

## Resources

The following resources are used by this module:

- [azurerm_application_security_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_private_dns_zone"></a> [private\_dns\_zone](#module\_private\_dns\_zone)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.1.1

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

### <a name="module_servicebus"></a> [servicebus](#module\_servicebus)

Source: ../../

Version:

### <a name="module_vnet"></a> [vnet](#module\_vnet)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: 0.1.4

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->