resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg"
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

resource "azurerm_lb" "internal_lb" {
  name                = "backend-internal-lb"
  location            = var.resource_group.loc
  resource_group_name = var.resource_group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name      = "internal-frontend-ip"
    subnet_id = var.config.other.private_subnet_id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.internal_lb.id
}

resource "azurerm_lb_probe" "lb_probe" {
  for_each            = toset(["80", "443", "3000", "8000"])
  loadbalancer_id     = azurerm_lb.internal_lb.id
  name                = "tcp-probe-${each.value}"
  protocol            = "Tcp"
  port                = tonumber(each.value)
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  for_each                       = toset(["80", "443", "3000", "8000"])
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "tcp-rule-${each.value}"
  protocol                       = "Tcp"
  frontend_port                  = tonumber(each.value)
  backend_port                   = tonumber(each.value)
  frontend_ip_configuration_name = "internal-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe[each.value].id
}

resource "azurerm_linux_virtual_machine_scale_set" "backend_vmss" {
  name                = "backend-vmss"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.loc
  sku                 = "Standard_B1ls"
  instances           = 2
  admin_username      = var.config.username
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    acr_login_server = var.config.acr.login_server
    acr_username     = var.config.acr.username
    acr_password     = var.config.acr.password
    db_name          = azurerm_mysql_flexible_database.main_db.name
    db_user          = azurerm_mysql_flexible_server.mysql_server.administrator_login
    db_password      = azurerm_mysql_flexible_server.mysql_server.administrator_password
    db_host          = azurerm_mysql_flexible_server.mysql_server.fqdn
  }))

  lifecycle {
    ignore_changes = [instances]
  }

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
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = "primary-nic"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.backend_nsg.id

    ip_configuration {
      name                                   = "internal-ip-config"
      primary                                = true
      subnet_id                              = var.config.other.private_subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_pool.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "backend-autoscale-rules"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.loc
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.backend_vmss.id

  profile {
    name = "default-profile"

    capacity {
      default = 2
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.backend_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.backend_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
