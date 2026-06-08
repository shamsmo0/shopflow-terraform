
resource "azurerm_virtual_network" "main_vnet" {
  name                = "main_vnet"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "private_db_subnet" {
  name                 = "private-db-subnet"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "db-delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


resource "azurerm_route_table" "public_rt" {
  name                = "public-route-table"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name

  route {
    name           = "internet-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "public_rt_assoc" {
  subnet_id      = azurerm_subnet.public_subnet.id
  route_table_id = azurerm_route_table.public_rt.id
}

resource "azurerm_route_table" "private_rt" {
  name                = "private-route-table"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name
}

resource "azurerm_subnet_route_table_association" "private_rt_assoc" {
  subnet_id      = azurerm_subnet.private_subnet.id
  route_table_id = azurerm_route_table.private_rt.id
}

resource "azurerm_subnet_route_table_association" "private_rt_db_assoc" {
  subnet_id      = azurerm_subnet.private_db_subnet.id
  route_table_id = azurerm_route_table.private_rt.id
}

########################################## This is NAT
resource "azurerm_public_ip" "nat_pip" {
  name                = "nat-gateway-pip"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "nat-gateway"
  location                = var.resource_group.loc
  resource_group_name     = var.resource_group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_subnet_assoc" {
  subnet_id      = azurerm_subnet.private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}
