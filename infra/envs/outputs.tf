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
output "apim_identity_principal_id" {
  description = "Principal ID of the APIM system-assigned managed identity"
  value       = module.apim.apim_identity_principal_id
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App system-assigned managed identity"
  value       = module.function_app.function_app_identity_principal_id
}

output "foundry_agent_principal_id" {
  description = "Principal ID of the Foundry Agent's Managed Identity (provided)"
  value       = var.foundry_agent_principal_id
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
  APIM Managed Identity: ${module.apim.apim_identity_principal_id}
  Function App Managed Identity: ${module.function_app.function_app_identity_principal_id}
  Foundry Agent Principal ID: ${var.foundry_agent_principal_id != "" ? var.foundry_agent_principal_id : "(Not configured - any MI allowed)"}

Next Steps:
1. Deploy Function App code from backend/function_app/
2. Deploy Web App code from frontend/react_app/
3. Configure Foundry Agent with APIM endpoint
4. Test end-to-end flow

=======================================================
EOT
}
