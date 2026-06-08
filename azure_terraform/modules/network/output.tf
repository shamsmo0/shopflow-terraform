output "private_subnet_id" {
  value = azurerm_subnet.private_subnet.id
}

output "public_subnet_id" {
  value = azurerm_subnet.public_subnet.id
}

output "private_db_subnet_id" {
  value = azurerm_subnet.private_db_subnet.id
}

output "vnetId" {
  value = azurerm_virtual_network.main_vnet.id
}
