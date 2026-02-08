# API Management
resource "azurerm_api_management" "main" {
  name                = "apim-${var.project_name}-${var.environment}-${random_string.apim_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  # System-assigned Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # SECURITY: Internal mode for private networking
  virtual_network_type = "Internal"
  
  virtual_network_configuration {
    subnet_id = var.apim_subnet_id
  }

  # Minimum TLS version
  min_api_version = "2021-08-01"

  tags = var.tags

  # APIM takes 25-40 minutes to provision
  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
}

resource "random_string" "apim_suffix" {
  length  = 6
  special = false
  upper   = false
}

# API Definition
resource "azurerm_api_management_api" "mcp" {
  name                  = "mcp-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.main.name
  revision              = "1"
  display_name          = "MCP Server API"
  path                  = "mcp"
  protocols             = ["https"]
  subscription_required = false  # Using Entra ID instead

  service_url = "https://${var.function_app_hostname}"
}

# API Operation - Health Check
resource "azurerm_api_management_api_operation" "health" {
  operation_id        = "health-check"
  api_name            = azurerm_api_management_api.mcp.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = "Health Check"
  method              = "GET"
  url_template        = "/health"
  description         = "Health check endpoint"

  response {
    status_code = 200
    description = "Success"
  }
}

# API Operation - MCP Endpoint (placeholder for future)
resource "azurerm_api_management_api_operation" "mcp_endpoint" {
  operation_id        = "mcp-endpoint"
  api_name            = azurerm_api_management_api.mcp.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  display_name        = "MCP Endpoint"
  method              = "POST"
  url_template        = "/api/*"
  description         = "MCP server endpoint"

  response {
    status_code = 200
    description = "Success"
  }
}

# SECURITY: Inbound Policy with Managed Identity Validation
resource "azurerm_api_management_api_policy" "mcp" {
  api_name            = azurerm_api_management_api.mcp.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  xml_content = templatefile("${path.module}/policy.xml.tpl", {
    tenant_id                   = var.tenant_id
    function_app_hostname       = var.function_app_hostname
    foundry_agent_principal_id  = var.foundry_agent_principal_id
  })
}

# Named Value for Foundry Agent Principal ID (for reference in policies)
resource "azurerm_api_management_named_value" "foundry_principal_id" {
  count               = var.foundry_agent_principal_id != "" ? 1 : 0
  name                = "foundry-agent-principal-id"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = "Foundry-Agent-Principal-ID"
  value               = var.foundry_agent_principal_id
  secret              = false
}

# Diagnostic Settings for APIM
resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                       = "diag-apim-${var.environment}"
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# RBAC: Grant APIM Managed Identity access to Function App
resource "azurerm_role_assignment" "apim_to_function" {
  scope                = var.function_app_id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_api_management.main.identity[0].principal_id
}
