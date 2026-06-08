variable "config" {
  type = object({
    ssh_key_path = string
    password     = string
    username     = string
  })
}

variable "state" {
  type = object({
    access_key           = string
    storage_account_name = string
  })
}
