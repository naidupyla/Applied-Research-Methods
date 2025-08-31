package pac.network

deny[msg] {
  resource := input.planned_values.root_module.resources[_]
  resource.type == "azurerm_virtual_network"
  msg := sprintf("Creation of VNet '%v' is blocked.", [resource.name])
}

deny[msg] {
  resource := input.planned_values.root_module.resources[_]
  resource.type == "azurerm_subnet"
  msg := sprintf("Creation of Subnet '%v' is blocked.", [resource.name])
}
