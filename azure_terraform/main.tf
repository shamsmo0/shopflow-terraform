resource "azurerm_resource_group" "rg" {
  name     = "terrafrom-project"
  location = "polandcentral"
}

module "network" {
  source = "./modules/network"
  global_conf = {
    address_space = "10.0.0.0/16"
  }
  resource_group = {
    loc  = azurerm_resource_group.rg.location
    name = azurerm_resource_group.rg.name
  }
}

module "acr" {
  source = "./modules/acr"
  resource_group = {
    loc  = azurerm_resource_group.rg.location
    name = azurerm_resource_group.rg.name
  }
}

module "vm" {
  source = "./modules/vms"
  resource_group = {
    loc  = azurerm_resource_group.rg.location
    name = azurerm_resource_group.rg.name
  }
  config = {
    username = var.config.username
    ssh_key  = var.config.ssh_key_path
    vnet_id  = module.network.vnetId
    bastion = {
      subnetId = module.network.public_subnet_id
    }
    other = {
      private_subnet_id = module.network.private_subnet_id
    }
    db = {
      administrator_password = var.config.password
      db_admin_username      = var.config.username
      private_subnet_db_id   = module.network.private_db_subnet_id
    }
    acr = {
      login_server = module.acr.acr_login_server
      username     = module.acr.acr_token_username
      password     = module.acr.acr_token_password
    }
  }
}

