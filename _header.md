# Terraform Azure Service Bus Namespace Module

This Terraform module is designed to create Azure Service bus namespaces and its related resources, including queues and topics.

> [!WARNING]
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>

## Features

* Creation of queues.
* Creation of topics and its subscriptions on it
* EntraID authentication instead of access keys
* Support for customer-managed keys and double encryption with infrastructure encryption.
* Enable private endpoint, providing secure access over a private network.
* Enable diagnostic settings.
* Creation of role assignments
* Enable locks
* Enable managed identities both system and user assigned ones.

## Limitations

* The module does not support configuring failover for premium tiers
* The module does not support subscription filters when creating topics

Private endpoints are created only for Premium namespaces; Basic and Standard continue to ignore endpoint creation. Service Bus supports the `namespace` subresource and IP configuration member, including static IP addresses. Omitted names and member names retain their existing defaults. Endpoint `resource_group_name` accepts a resource group name, not an ARM ID.

Endpoint role assignment names, descriptions, conditions, principal types, and lock notes are now applied rather than discarded. Existing namespace, endpoint, role assignment, and lock addresses remain unchanged. Review the plan before applying previously ignored role assignment values, as these can replace the assignment. Reusing a role assignment map key across multiple endpoints remains unsupported.

## Upgrading to the AzAPI resources

The locks, role assignments and diagnostic settings move from AzureRM to AzAPI with `moved` blocks, so the plan after upgrading reports them as moved and Azure keeps them. Two cases need extra steps:

- **`ReadOnly` lock.** The upgrade updates resources in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration without the lock using the old version, then upgrade and restore the lock.
- **Cross-tenant role assignments** (those that set `delegated_managed_identity_resource_id`, for example with Azure Lighthouse). The AzureRM provider stored their ID with a `|<tenant-id>` suffix that a `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module. The key is the same as in the old address, for example `Namespace|<role key>` or `Queue|<role key>|<queue name>`:

  ```shell
  terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
  ```

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.role_assignments["<key>"]
    id = "<role assignment resource ID, without the |<tenant-id> suffix>"
  }
  ```

## Examples
* [Use only defaults values](examples/default/main.tf)
* [Specifying all possible parameters at namespace level](examples/max-namespace/main.tf)
* [Creation of queues](examples/queues/main.tf)
* [Creation of topics](examples/topics/main.tf)
* [Customer managed key pinning to a specific key version](examples/cmk-pin-key-version/main.tf)
* [Customer managed key using auto rotation](examples/cmk-with-auto-rotate/main.tf)
* [Enable diagnostic settings](examples/diagnostic-settings/main.tf)
* [Enable managed identities](examples/managed-identities/main.tf)
* [Enable private endpoints with auto management of dns records](examples/private-endpoints-managed-dns-records/main.tf)
* [Restrict public network access with access control list and service endpoints](examples/public-restricted-access/main.tf)
