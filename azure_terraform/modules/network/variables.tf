variable "resource_group" {
  type = object({
    name = string
    loc  = string
  })
}

variable "global_conf" {
  type = object({
    address_space = string
  })
}
