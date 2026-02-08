# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# Networking
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

# Monitoring
output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_name
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = module.monitoring.application_insights_name
}

# Identity
output "apim_api_application_id" {
  description = "Application ID of the APIM API app registration"
  value       = module.identity.apim_api_application_id
}

output "apim_api_identifier_uri" {
  description = "Identifier URI for the APIM API"
  value       = module.identity.apim_api_identifier_uri
}

output "foundry_agent_application_id" {
  description = "Application ID of the Foundry Agent"
  value       = module.identity.foundry_agent_application_id
}

output "foundry_agent_client_secret" {
  description = "Client secret for Foundry Agent (if created)"
  value       = module.identity.foundry_agent_client_secret
  sensitive   = true
}

# Function App
output "function_app_name" {
  description = "Name of the Function App"
  value       = module.function_app.function_app_name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = module.function_app.function_app_default_hostname
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = module.function_app.storage_account_name
}

# APIM
output "apim_name" {
  description = "Name of the API Management instance"
  value       = module.apim.apim_name
}

output "apim_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = module.apim.apim_gateway_url
}

output "apim_private_ip_addresses" {
  description = "Private IP addresses of the API Management instance"
  value       = module.apim.apim_private_ip_addresses
}

# Web App
output "webapp_name" {
  description = "Name of the Web App"
  value       = module.webapp.webapp_name
}

output "webapp_default_hostname" {
  description = "Default hostname of the Web App"
  value       = module.webapp.webapp_default_hostname
}

# Deployment Instructions
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = <<EOT
=======================================================
   Azure MCP Gateway - Deployment Summary (DEV)
=======================================================

Resource Group: ${azurerm_resource_group.main.name}
Location: ${var.location}

APIM:
  Name: ${module.apim.apim_name}
  Private IP: ${join(", ", module.apim.apim_private_ip_addresses)}
  Gateway URL: ${module.apim.apim_gateway_url}

Function App:
  Name: ${module.function_app.function_app_name}
  Hostname: ${module.function_app.function_app_default_hostname}

Web App:
  Name: ${module.webapp.webapp_name}
  Hostname: ${module.webapp.webapp_default_hostname}

Identity:
  APIM API ID: ${module.identity.apim_api_identifier_uri}
  Foundry Agent Client ID: ${module.identity.foundry_agent_application_id}

Next Steps:
1. Deploy Function App code from backend/function_app/
2. Deploy Web App code from frontend/react_app/
3. Configure Foundry Agent with APIM endpoint
4. Test end-to-end flow

=======================================================
EOT
}
