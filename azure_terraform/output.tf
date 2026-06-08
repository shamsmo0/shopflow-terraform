output "bastion_public_ip" {
  value = module.vm.bastion_public_ip
}

output "acr_server" {
  value = module.acr.acr_login_server
}


output "acr_login_user" {
  value = module.acr.acr_token_username
}

output "acr_password" {
  value     = module.acr.acr_token_password
  sensitive = true
}
