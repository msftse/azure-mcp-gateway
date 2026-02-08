output "apim_id" {
  description = "ID of the API Management instance"
  value       = azurerm_api_management.main.id
}

output "apim_name" {
  description = "Name of the API Management instance"
  value       = azurerm_api_management.main.name
}

output "apim_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = azurerm_api_management.main.gateway_url
}

output "apim_private_ip_addresses" {
  description = "Private IP addresses of the API Management instance"
  value       = azurerm_api_management.main.private_ip_addresses
}

output "apim_identity_principal_id" {
  description = "Principal ID of the APIM system-assigned managed identity"
  value       = azurerm_api_management.main.identity[0].principal_id
}

output "apim_identity_tenant_id" {
  description = "Tenant ID of the APIM system-assigned managed identity"
  value       = azurerm_api_management.main.identity[0].tenant_id
}
