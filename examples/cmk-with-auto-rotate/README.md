<!-- BEGIN_TF_DOCS -->
# Customer managed key without pinned version example

This deploys the module with a customer managed key configured without specifying a version which will support auto rotate of keys

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  prefix   = "cmk-auto"
  key_name = "customermanagedkey"
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

resource "azurerm_user_assigned_identity" "example" {
  name = "example-${local.prefix}"

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_key_vault" "example" {
  name = "${module.naming.key_vault.name_unique}${local.prefix}"

  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  purge_protection_enabled   = true
  sku_name                   = "standard"
  resource_group_name        = azurerm_resource_group.example.name
  location                   = azurerm_resource_group.example.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_key" "example" {
  name = local.key_name

  key_size     = 4096
  key_type     = "RSA"
  key_vault_id = azurerm_key_vault.example.id

  key_opts = [
    "wrapKey",
    "unwrapKey"
  ]
}

resource "azurerm_role_assignment" "crypto_officer" {
  role_definition_name = "Key Vault Crypto Officer"

  scope        = azurerm_key_vault.example.id
  principal_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "crypto_service_encryption_user" {
  role_definition_name = "Key Vault Crypto Service Encryption User"

  scope        = azurerm_key_vault.example.id
  principal_id = azurerm_user_assigned_identity.example.principal_id
}

module "servicebus" {
  source = "../../"

  infrastructure_encryption_enabled = true
  sku                               = "Premium"
  resource_group_name               = azurerm_resource_group.example.name
  location                          = azurerm_resource_group.example.location
  name                              = "${module.naming.servicebus_namespace.name_unique}-${local.prefix}"

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example.id]
  }

  customer_managed_key = {
    key_name              = local.key_name
    key_vault_resource_id = azurerm_key_vault.example.id

    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.example.id
    }
  }

  depends_on = [azurerm_role_assignment.crypto_officer, azurerm_role_assignment.crype_service_encryption_user]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_key.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.crypto_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.crypto_service_encryption_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_user_assigned_identity.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
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

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

### <a name="module_servicebus"></a> [servicebus](#module\_servicebus)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->