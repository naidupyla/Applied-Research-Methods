 terraform {
    required_providers {
      azurerm = {
        source  = "hashicorp/azurerm"
        # version = "~> 3.97.1"
      }
      azuread = {
        source  = "hashicorp/azuread"
        version = "~> 2.47.0"
      }
    }

    required_version = ">= 1.3.0"
  }

  provider "azurerm" {
    features {}
    
    client_id =  "9afd19e1-f940-4fb2-bb0f-f770d9582956"
    //removed secret value 
    subscription_id = "3fe970b5-7227-40ec-b4ce-c77ef4efffb6"
    tenant_id  = "5318eefe-8bca-4f0f-a115-d1a32583e5e9"
    
  }

  provider "azuread" {
  }

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Networking
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Insecure: SSH open to Internet
  security_rule {
    name                       = "allow-ssh-from-anywhere"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Storage (intentionally lax)

# resource "azurerm_storage_account" "sa" {
#   name                             = "${var.prefix}sa"
#   resource_group_name              = azurerm_resource_group.rg.name
#   location                         = azurerm_resource_group.rg.location
#   account_tier                     = "Standard"
#   account_replication_type         = "LRS"
#   public_network_access_enabled    = true
#   # Many tenants now enforce TLS1_2 minimum; we won't try to lower it to avoid deployment failures.
#   min_tls_version                  = "TLS1_2"
#   tags                             = var.tags
# }

resource "azurerm_storage_account" "sa" {
  name                          = "${var.prefix}sa"
  resource_group_name           = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  public_network_access_enabled = true
  allow_nested_items_to_be_public = true # Enable public blob/container access
  min_tls_version              = "TLS1_2"
  tags                        = var.tags
}



# VM (Linux) - Standard_B1s with password auth enabled + public IP
# resource "azurerm_public_ip" "vm" {
#   name                = "${var.prefix}-vm-pip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Dynamic"
#   sku                 = "Basic"
#   tags                = var.tags
# }

resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.vm.id
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  admin_password                  = var.insecure_admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}

# Key Vault (insecure: broad network access, purge protection disabled)

resource "azurerm_key_vault" "kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  # Soft delete is always on by platform; we keep purge protection off for a failing control.
  public_network_access_enabled = true
  network_acls {
    default_action = "Allow"    # wide open (no firewall)
    bypass         = "AzureServices"
  }
  tags = var.tags
}

# Access policy just for the current principal (so Terraform can create the vault cleanly)
resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "List", "Delete"]
}
