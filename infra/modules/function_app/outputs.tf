output "function_app_id" {
  description = "ID of the Function App"
  value       = azurerm_linux_function_app.main.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.main.name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App system-assigned managed identity"
  value       = azurerm_linux_function_app.main.identity[0].principal_id
}

output "function_app_identity_tenant_id" {
  description = "Tenant ID of the Function App system-assigned managed identity"
  value       = azurerm_linux_function_app.main.identity[0].tenant_id
}

output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.function.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.function.name
}

output "function_app_private_endpoint_ip" {
  description = "Private IP address of the Function App private endpoint"
  value       = azurerm_private_endpoint.function.private_service_connection[0].private_ip_address
}
