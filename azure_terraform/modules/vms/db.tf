resource "azurerm_private_dns_zone" "mysql_dns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dns.name
  virtual_network_id    = var.config.vnet_id
  resource_group_name   = var.resource_group.name
}

resource "azurerm_mysql_flexible_server" "mysql_server" {
  name                   = "backend-mysql-server-terraform-project" # Must be globally unique
  resource_group_name    = var.resource_group.name
  location               = var.resource_group.loc
  administrator_login    = var.config.db.db_admin_username
  administrator_password = var.config.db.administrator_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  backup_retention_days  = 7

  delegated_subnet_id = var.config.db.private_subnet_db_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql_dns.id

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_dns_link]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }
}

resource "azurerm_mysql_flexible_database" "main_db" {
  name                = "shopflow_db"
  resource_group_name = var.resource_group.name
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  charset             = "utf8mb3"
  collation           = "utf8mb3_unicode_ci"
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "mysql-db-nsg"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name

  security_rule {
    name                       = "AllowMySQLFromCompute"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id                 = var.config.db.private_subnet_db_id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}
