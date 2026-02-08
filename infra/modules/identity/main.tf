terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

data "azuread_client_config" "current" {}

# App Registration for APIM API
resource "azuread_application" "apim_api" {
  display_name = "apim-api-${var.project_name}-${var.environment}"
  owners       = [data.azuread_client_config.current.object_id]

  # Application ID URI
  identifier_uris = ["api://${var.project_name}-${var.environment}"]

  # Expose API scope
  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow access to MCP API"
      admin_consent_display_name = "Access MCP API"
      enabled                    = true
      id                         = random_uuid.apim_scope_id.result
      type                       = "User"
      user_consent_description   = "Allow access to MCP API"
      user_consent_display_name  = "Access MCP API"
      value                      = "API.Access"
    }
  }

  # Pre-authorize Foundry Agent if client ID provided
  dynamic "api" {
    for_each = var.foundry_agent_client_id != null ? [1] : []
    content {
      pre_authorized_application {
        application_id = var.foundry_agent_client_id
        permission_ids = [random_uuid.apim_scope_id.result]
      }
    }
  }
}

resource "random_uuid" "apim_scope_id" {}

# Service Principal for APIM API App Registration
resource "azuread_service_principal" "apim_api" {
  application_id = azuread_application.apim_api.application_id
  owners         = [data.azuread_client_config.current.object_id]
}

# Foundry Agent App Registration (if creating new)
resource "azuread_application" "foundry_agent" {
  count        = var.create_foundry_agent ? 1 : 0
  display_name = "foundry-agent-${var.project_name}-${var.environment}"
  owners       = [data.azuread_client_config.current.object_id]

  # Required API permissions for calling APIM
  required_resource_access {
    resource_app_id = azuread_application.apim_api.application_id

    resource_access {
      id   = random_uuid.apim_scope_id.result
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "foundry_agent" {
  count          = var.create_foundry_agent ? 1 : 0
  application_id = azuread_application.foundry_agent[0].application_id
  owners         = [data.azuread_client_config.current.object_id]
}

# Client secret for Foundry Agent (if creating new)
resource "azuread_application_password" "foundry_agent" {
  count                 = var.create_foundry_agent ? 1 : 0
  application_object_id = azuread_application.foundry_agent[0].object_id
  display_name          = "Terraform Generated Secret"
  end_date_relative     = "8760h" # 1 year
}

# User-assigned Managed Identity for APIM (Alternative to System-assigned)
# Note: System-assigned MI is created automatically by APIM, so this is optional
resource "azurerm_user_assigned_identity" "apim" {
  count               = var.create_user_assigned_mi ? 1 : 0
  name                = "id-apim-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
