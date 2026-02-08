# Identity Module - Managed Identity Only
# This module no longer creates App Registrations
# All authentication uses System-assigned Managed Identities

# Note: System-assigned Managed Identities are created automatically by:
# - Azure API Management
# - Azure Function App
# - Azure App Service (Web App)

# This module is a placeholder for future identity-related resources
# such as user-assigned managed identities if needed

# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# Optional: User-assigned Managed Identity (if needed for cross-resource scenarios)
resource "azurerm_user_assigned_identity" "optional" {
  count               = var.create_user_assigned_mi ? 1 : 0
  name                = "id-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
