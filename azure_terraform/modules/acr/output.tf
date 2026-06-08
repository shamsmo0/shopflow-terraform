output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_token_username" {
  value = azurerm_container_registry_token.acr_token.name
}

output "acr_token_password" {
  value     = azurerm_container_registry_token_password.acr_token_pass.password1[0].value
  sensitive = true
}
