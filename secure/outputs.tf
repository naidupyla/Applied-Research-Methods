output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

# output "vm_public_ip" {
#   value = azurerm_public_ip.vm.ip_address
# }
