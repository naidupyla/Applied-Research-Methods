package storage

# Deny storage accounts with public network access enabled
deny[reason] {
    input.resource_type == "azurerm_storage_account"
    input.values contains {"public_network_access_enabled": true}
    reason := sprintf("Storage account '%s' has public network access enabled.", [input.name])
}
