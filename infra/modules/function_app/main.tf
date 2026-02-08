# Storage Account for Function App
resource "azurerm_storage_account" "function" {
  name                     = "st${var.project_name}${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  # SECURITY: Disable public access
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  # Enable blob versioning for backup
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Private Endpoints for Storage Account
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-${azurerm_storage_account.function.name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_pe_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.function.name}-blob"
    private_connection_resource_id = azurerm_storage_account.function.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-blob"
    private_dns_zone_ids = [var.private_dns_zone_blob_id]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_file" {
  name                = "pe-${azurerm_storage_account.function.name}-file"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_pe_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.function.name}-file"
    private_connection_resource_id = azurerm_storage_account.function.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-file"
    private_dns_zone_ids = [var.private_dns_zone_file_id]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_queue" {
  name                = "pe-${azurerm_storage_account.function.name}-queue"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_pe_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.function.name}-queue"
    private_connection_resource_id = azurerm_storage_account.function.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-queue"
    private_dns_zone_ids = [var.private_dns_zone_queue_id]
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_table" {
  name                = "pe-${azurerm_storage_account.function.name}-table"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_pe_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.function.name}-table"
    private_connection_resource_id = azurerm_storage_account.function.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-table"
    private_dns_zone_ids = [var.private_dns_zone_table_id]
  }

  tags = var.tags
}

# App Service Plan for Functions
resource "azurerm_service_plan" "function" {
  name                = "asp-func-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.function_app_plan_sku

  tags = var.tags
}

# Function App
resource "azurerm_linux_function_app" "main" {
  name                       = "func-${var.project_name}-${var.environment}-${random_string.function_suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.function.id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key

  # SECURITY: Disable public access
  public_network_access_enabled = false
 
  # System-assigned Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # Application settings
  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.application_insights_connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = var.function_runtime
    "WEBSITE_CONTENTOVERVNET"               = "1"  # Required for private storage
  }

  site_config {
    always_on                         = var.always_on
    application_insights_connection_string = var.application_insights_connection_string
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    
    # Python runtime
    application_stack {
      python_version = var.function_runtime_version
    }

    # CORS (only if origins are specified)
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins = var.cors_allowed_origins
      }
    }
  }

  # TODO: Enable Entra ID authentication
  # Requires app registration for Function App to validate tokens
  # auth_settings_v2 {
  #   auth_enabled           = true
  #   require_authentication = true
  #   unauthenticated_action = "Return401"
  #
  #   login {
  #     token_store_enabled = true
  #   }
  #
  #   active_directory_v2 {
  #     client_id              = "<function-app-registration-client-id>"
  #     tenant_auth_endpoint   = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
  #     allowed_audiences      = [
  #       "api://<function-app-registration-client-id>"
  #     ]
  #   }
  # }

  https_only = true

  tags = var.tags

  depends_on = [
    azurerm_private_endpoint.storage_blob,
    azurerm_private_endpoint.storage_file,
    azurerm_private_endpoint.storage_queue,
    azurerm_private_endpoint.storage_table
  ]
}

resource "random_string" "function_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Private Endpoint for Function App
resource "azurerm_private_endpoint" "function" {
  name                = "pe-${azurerm_linux_function_app.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.functions_pe_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_linux_function_app.main.name}"
    private_connection_resource_id = azurerm_linux_function_app.main.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "pdz-group-function"
    private_dns_zone_ids = [var.private_dns_zone_azurewebsites_id]
  }

  tags = var.tags
}
