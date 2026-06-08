resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "bastion_nsg"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVnetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "main" {
  name                = "bastion_nic"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name

  ip_configuration {
    name                          = "bastion_ip_config"
    subnet_id                     = var.config.bastion.subnetId
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "bastion_sec" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}


resource "azurerm_linux_virtual_machine" "bastion_mv" {
  name                            = "bastion"
  location                        = var.resource_group.loc
  resource_group_name             = var.resource_group.name
  size                            = "Standard_B1ls"
  admin_username                  = var.config.username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.main.id]
  depends_on = [
    azurerm_network_interface.main
  ]

  admin_ssh_key {
    username   = var.config.username
    public_key = var.config.ssh_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "bastion-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 50
  }

}
