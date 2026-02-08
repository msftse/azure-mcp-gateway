# App Service Plan for Web App
resource "azurerm_service_plan" "webapp" {
  name                = "asp-webapp-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.webapp_sku

  tags = var.tags
}

# Linux Web App for React Frontend
resource "azurerm_linux_web_app" "main" {
  name                      = "app-${var.project_name}-${var.environment}-${random_string.webapp_suffix.result}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.webapp.id
  https_only                = true
  
  # SECURITY: Disable public access
  public_network_access_enabled = false

  # VNet Integration for outbound traffic
  virtual_network_subnet_id = var.webapp_integration_subnet_id

  # System-assigned Managed Identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on         = var.always_on
    ftps_state        = "Disabled"
    http2_enabled     = true
    minimum_tls_version = "1.2"

    # Node.js runtime for React app
    application_stack {
      node_version = var.node_version
    }

    # CORS settings (only if origins are specified)
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = false
      }
    }
  }

  # Application settings
  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.application_insights_connection_string
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~${var.node_version}"
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
    
    # React environment variables (to be configured)
    "REACT_APP_FOUNDRY_ENDPOINT"            = var.foundry_endpoint
  }

  tags = var.tags
}

resource "random_string" "webapp_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Private Endpoint for Web App
resource "azurerm_private_endpoint" "webapp" {
  name                = "pe-${azurerm_linux_web_app.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.functions_pe_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_linux_web_app.main.name}"
    private_connection_resource_id = azurerm_linux_web_app.main.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-webapp"
    private_dns_zone_ids = [var.private_dns_zone_azurewebsites_id]
  }

  tags = var.tags
}

# Diagnostic Settings for Web App
resource "azurerm_monitor_diagnostic_setting" "webapp" {
  name                       = "diag-webapp-${var.environment}"
  target_resource_id         = azurerm_linux_web_app.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
