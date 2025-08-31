package terraform.storage

# Deny if public network access (string) is enabled
deny[reason] if {
    input.type == "azurerm_storage_account"
    val := input.values.public_network_access
    val == "Enabled"
    reason := sprintf("Storage Account '%s' has public network access enabled", [input.address])
}

# Deny if public network access (boolean) is enabled
deny[reason] if {
    input.type == "azurerm_storage_account"
    val := input.values.public_network_access_enabled
    val == true
    reason := sprintf("Storage Account '%s' has public network access enabled (bool)", [input.address])
}

# Deny if blob public access is allowed
deny[reason] if {
    input.type == "azurerm_storage_account"
    val := input.values.allow_nested_items_to_be_public
    val == true
    reason := sprintf("Storage Account '%s' allows public blob access", [input.address])
}
