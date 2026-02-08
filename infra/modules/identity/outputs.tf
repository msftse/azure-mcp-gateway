output "foundry_agent_principal_id" {
  description = "Principal ID of the Foundry Agent's Managed Identity (provided by customer)"
  value       = var.foundry_agent_principal_id
}

output "user_assigned_identity_id" {
  description = "ID of the optional user-assigned managed identity (if created)"
  value       = var.create_user_assigned_mi ? azurerm_user_assigned_identity.optional[0].id : null
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the optional user-assigned managed identity (if created)"
  value       = var.create_user_assigned_mi ? azurerm_user_assigned_identity.optional[0].principal_id : null
}

output "current_tenant_id" {
  description = "Current Azure AD tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}
