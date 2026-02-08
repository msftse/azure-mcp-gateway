terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Remote backend for state storage
  backend "azurerm" {
    # Configuration provided via backend-config.tfvars or environment variables
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "sttfstate..."
    # container_name       = "tfstate"
    # key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = var.tags
}

# Networking Module
module "networking" {
  source = "../modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  vnet_address_space                     = var.vnet_address_space
  apim_subnet_address_prefix             = var.apim_subnet_address_prefix
  functions_pe_subnet_address_prefix     = var.functions_pe_subnet_address_prefix
  webapp_integration_subnet_address_prefix = var.webapp_integration_subnet_address_prefix
  storage_pe_subnet_address_prefix       = var.storage_pe_subnet_address_prefix

  enable_nsgs = var.enable_nsgs

  tags = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "../modules/monitoring"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  log_retention_days  = var.log_retention_days
  disable_ip_masking  = var.disable_ip_masking

  tags = var.tags
}

# Identity Module
module "identity" {
  source = "../modules/identity"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  foundry_agent_principal_id = var.foundry_agent_principal_id

  tags = var.tags
}

# Function App Module
module "function_app" {
  source = "../modules/function_app"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id

  function_app_plan_sku   = var.function_app_plan_sku
  function_runtime        = var.function_runtime
  function_runtime_version = var.function_runtime_version

  application_insights_connection_string = module.monitoring.application_insights_connection_string

  functions_pe_subnet_id              = module.networking.functions_pe_subnet_id
  storage_pe_subnet_id                = module.networking.storage_pe_subnet_id
  private_dns_zone_azurewebsites_id   = module.networking.private_dns_zone_azurewebsites_id
  private_dns_zone_blob_id            = module.networking.private_dns_zone_blob_id
  private_dns_zone_file_id            = module.networking.private_dns_zone_file_id
  private_dns_zone_queue_id           = module.networking.private_dns_zone_queue_id
  private_dns_zone_table_id           = module.networking.private_dns_zone_table_id

  tags = var.tags
}

# APIM Module
module "apim" {
  source = "../modules/apim"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id

  publisher_name  = var.apim_publisher_name
  publisher_email = var.apim_publisher_email
  sku_name        = var.apim_sku_name

  apim_subnet_id                = module.networking.apim_subnet_id
  function_app_id               = module.function_app.function_app_id
  function_app_hostname         = module.function_app.function_app_default_hostname
  foundry_agent_principal_id    = var.foundry_agent_principal_id
  log_analytics_workspace_id    = module.monitoring.log_analytics_workspace_id

  tags = var.tags

  depends_on = [module.function_app]
}

# Web App Module
module "webapp" {
  source = "../modules/webapp"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  webapp_sku     = var.webapp_sku
  node_version   = var.node_version
  foundry_endpoint = var.foundry_endpoint

  application_insights_connection_string = module.monitoring.application_insights_connection_string

  webapp_integration_subnet_id        = module.networking.webapp_integration_subnet_id
  functions_pe_subnet_id              = module.networking.functions_pe_subnet_id
  private_dns_zone_azurewebsites_id   = module.networking.private_dns_zone_azurewebsites_id
  log_analytics_workspace_id          = module.monitoring.log_analytics_workspace_id

  tags = var.tags
}
