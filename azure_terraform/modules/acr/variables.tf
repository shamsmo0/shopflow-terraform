variable "resource_group" {
  type = object({
    name = string
    loc  = string
  })
}
