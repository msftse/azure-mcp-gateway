output "apim_api_application_id" {
  description = "Application ID of the APIM API app registration"
  value       = azuread_application.apim_api.application_id
}

output "apim_api_object_id" {
  description = "Object ID of the APIM API app registration"
  value       = azuread_application.apim_api.object_id
}

output "apim_api_identifier_uri" {
  description = "Identifier URI for the APIM API"
  value       = azuread_application.apim_api.identifier_uris[0]
}

output "foundry_agent_application_id" {
  description = "Application ID of the Foundry Agent (if created)"
  value       = var.create_foundry_agent ? azuread_application.foundry_agent[0].application_id : var.foundry_agent_client_id
}

output "foundry_agent_object_id" {
  description = "Object ID of the Foundry Agent (if created)"
  value       = var.create_foundry_agent ? azuread_application.foundry_agent[0].object_id : null
}

output "foundry_agent_client_secret" {
  description = "Client secret for Foundry Agent (if created)"
  value       = var.create_foundry_agent ? azuread_application_password.foundry_agent[0].value : null
  sensitive   = true
}

output "user_assigned_identity_id" {
  description = "ID of the user-assigned managed identity (if created)"
  value       = var.create_user_assigned_mi ? azurerm_user_assigned_identity.apim[0].id : null
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity (if created)"
  value       = var.create_user_assigned_mi ? azurerm_user_assigned_identity.apim[0].principal_id : null
}
