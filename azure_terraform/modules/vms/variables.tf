variable "resource_group" {
  type = object({
    name = string
    loc  = string
  })
}


variable "config" {
  type = object({
    username = string
    ssh_key  = string
    vnet_id  = string
    other = object({
      private_subnet_id = string
    })
    bastion = object({
      subnetId = string
    })
    db = object({
      private_subnet_db_id   = string
      db_admin_username      = string
      administrator_password = string
    })
    acr = object({
      login_server = string
      username     = string
      password     = string
    })
  })
}
