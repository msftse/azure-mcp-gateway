output "webapp_id" {
  description = "ID of the Web App"
  value       = azurerm_linux_web_app.main.id
}

output "webapp_name" {
  description = "Name of the Web App"
  value       = azurerm_linux_web_app.main.name
}

output "webapp_default_hostname" {
  description = "Default hostname of the Web App"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "webapp_identity_principal_id" {
  description = "Principal ID of the Web App system-assigned managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "webapp_identity_tenant_id" {
  description = "Tenant ID of the Web App system-assigned managed identity"
  value       = azurerm_linux_web_app.main.identity[0].tenant_id
}

output "webapp_private_endpoint_ip" {
  description = "Private IP address of the Web App private endpoint"
  value       = azurerm_private_endpoint.webapp.private_service_connection[0].private_ip_address
}
