output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "container_app_fqdn" {
  value = try(azurerm_container_app.app[0].ingress[0].fqdn, "")
}
