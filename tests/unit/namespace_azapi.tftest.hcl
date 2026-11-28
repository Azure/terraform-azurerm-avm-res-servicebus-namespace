override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace"
    output = {
      properties = {
        serviceBusEndpoint = "https://test-namespace.servicebus.windows.net:443/"
      }
    }
  }
}

override_resource {
  target = azapi_resource.authorization_rules
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/AuthorizationRules/rule"
  }
}

override_data {
  target = data.azapi_resource_action.default_keys
  values = {
    sensitive_output = {
      primaryConnectionString   = "Endpoint=sb://test-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=primary"
      primaryKey                = "primary"
      secondaryConnectionString = "Endpoint=sb://test-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=secondary"
      secondaryKey              = "secondary"
    }
  }
}

override_data {
  target = data.azapi_resource_action.authorization_rule_keys
  values = {
    sensitive_output = {
      primaryConnectionString   = "Endpoint=sb://test-namespace.servicebus.windows.net/;SharedAccessKeyName=rule;SharedAccessKey=rule-primary"
      primaryKey                = "rule-primary"
      secondaryConnectionString = "Endpoint=sb://test-namespace.servicebus.windows.net/;SharedAccessKeyName=rule;SharedAccessKey=rule-secondary"
      secondaryKey              = "rule-secondary"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
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
}

run "premium_body_with_customer_managed_key" {
  command = apply

  variables {
    sku                          = "Premium"
    capacity                     = 2
    premium_messaging_partitions = 2
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai"]
    }
    customer_managed_key = {
      key_name              = "cmk"
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.KeyVault/vaults/kv-test"
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai"
      }
    }
    network_rule_config = {
      default_action   = "Deny"
      cidr_or_ip_rules = ["10.0.0.0/24"]
      network_rules = [
        { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/sb" }
      ]
    }
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test" && azapi_resource.this.type == "Microsoft.ServiceBus/namespaces@2024-01-01"
    error_message = "The namespace MUST be created in the resource group with the API version azurerm used."
  }

  assert {
    condition     = azapi_resource.this.body.sku == { capacity = 2, name = "Premium", tier = "Premium" } && azapi_resource.this.body.properties.premiumMessagingPartitions == 2
    error_message = "Premium MUST send the capacity and the messaging partitions."
  }

  assert {
    condition     = azapi_resource.this.body.properties.disableLocalAuth == false && azapi_resource.this.body.properties.minimumTlsVersion == "1.2" && azapi_resource.this.body.properties.publicNetworkAccess == "Enabled"
    error_message = "Local auth, TLS version and public network access MUST be sent as azurerm sent them."
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.encryption) == jsonencode({
      keySource = "Microsoft.KeyVault"
      keyVaultProperties = [{
        identity    = { userAssignedIdentity = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai" }
        keyName     = "cmk"
        keyVaultUri = "https://kv-test.vault.azure.net/"
        keyVersion  = null
      }]
      requireInfrastructureEncryption = true
    })
    error_message = "The customer managed key MUST be sent with the key vault base URL and the identity."
  }

  assert {
    condition = jsonencode(azapi_update_resource.network_rule_set.body.properties) == jsonencode({
      defaultAction               = "Deny"
      ipRules                     = [{ action = "Allow", ipMask = "10.0.0.0/24" }]
      publicNetworkAccess         = "Enabled"
      trustedServiceAccessEnabled = false
      virtualNetworkRules         = [{ ignoreMissingVnetServiceEndpoint = false, subnet = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/sb" } }]
    })
    error_message = "The network rule set MUST carry the IP and virtual network rules."
  }

  assert {
    condition     = output.resource.customer_managed_key[0].key_vault_key_id == "https://kv-test.vault.azure.net/keys/cmk" && output.resource.network_rule_set[0].network_rules[0].subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/sb"
    error_message = "The resource output MUST keep the azurerm customer_managed_key and network_rule_set attributes."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "standard_body_and_default_keys" {
  command = apply

  variables {
    sku = "Standard"
    network_rule_config = {
      cidr_or_ip_rules = ["10.0.0.1"]
      network_rules = [
        { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/sb" }
      ]
    }
  }

  assert {
    condition     = jsonencode(azapi_resource.this.body.sku) == jsonencode({ capacity = null, name = "Standard", tier = "Standard" }) && azapi_resource.this.body.properties.premiumMessagingPartitions == null && azapi_resource.this.body.properties.encryption == null
    error_message = "Standard MUST NOT send a capacity, messaging partitions or encryption."
  }

  assert {
    condition     = jsonencode(azapi_update_resource.network_rule_set.body.properties.virtualNetworkRules) == "[]" && length(azapi_update_resource.network_rule_set.body.properties.ipRules) == 1
    error_message = "Standard MUST send IP rules only."
  }

  assert {
    condition     = output.resource.endpoint == "https://test-namespace.servicebus.windows.net:443/" && output.resource.capacity == 0 && output.resource.premium_messaging_partitions == 0
    error_message = "The resource output MUST keep the azurerm endpoint, capacity and partition attributes."
  }

  assert {
    condition     = nonsensitive(output.resource.default_primary_key) == "primary" && nonsensitive(output.resource.default_secondary_connection_string) == "Endpoint=sb://test-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=secondary"
    error_message = "The resource output MUST keep the keys of the default rule."
  }

  assert {
    condition     = data.azapi_resource_action.default_keys[0].resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test-namespace/AuthorizationRules/RootManageSharedAccessKey"
    error_message = "The default keys MUST be read from RootManageSharedAccessKey."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "no_default_keys_without_local_auth" {
  command = apply

  variables {
    sku                = "Standard"
    local_auth_enabled = false
  }

  assert {
    condition     = length(data.azapi_resource_action.default_keys) == 0 && output.resource.default_primary_key == null && azapi_resource.this.body.properties.disableLocalAuth == true
    error_message = "The default keys MUST NOT be read when SAS authentication is disabled."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}

run "authorization_rules_keep_rights_and_keys" {
  command = apply

  variables {
    sku = "Standard"
    authorization_rules = {
      manage = {
        manage = true
      }
      listen_only = {
        name   = "listener"
        listen = true
      }
    }
  }

  assert {
    condition     = azapi_resource.authorization_rules["manage"].name == "manage" && azapi_resource.authorization_rules["manage"].body.properties.rights == tolist(["Listen", "Send", "Manage"])
    error_message = "Manage MUST imply Listen and Send, in the order azurerm sent them, and the key MUST be the default name."
  }

  assert {
    condition     = azapi_resource.authorization_rules["listen_only"].name == "listener" && azapi_resource.authorization_rules["listen_only"].body.properties.rights == tolist(["Listen"])
    error_message = "A listen-only rule MUST keep its name and only the Listen right."
  }

  assert {
    condition     = output.resource_authorization_rules["manage"].send && output.resource_authorization_rules["manage"].listen && nonsensitive(output.resource_authorization_rules["manage"].primary_key) == "rule-primary"
    error_message = "The authorization rule output MUST keep the azurerm flags and keys."
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
}
