# Production environment uses the same main.tf as dev
# Symlink to dev main.tf to avoid duplication
# On Windows: mklink /H main.tf ..\dev\main.tf
# On Linux/Mac: ln ../dev/main.tf main.tf

# For now, include the same content as dev/main.tf
# In production use, you may want to customize this further

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

  backend "azurerm" {
    # Configuration provided via backend-config.tfvars
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

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = var.tags
}

module "networking" {
  source = "../../modules/networking"

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

module "monitoring" {
  source = "../../modules/monitoring"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  log_retention_days  = var.log_retention_days
  disable_ip_masking  = var.disable_ip_masking

  tags = var.tags
}

module "identity" {
  source = "../../modules/identity"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  create_foundry_agent    = var.create_foundry_agent
  foundry_agent_client_id = var.foundry_agent_client_id

  tags = var.tags
}

module "function_app" {
  source = "../../modules/function_app"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id

  function_app_plan_sku   = var.function_app_plan_sku
  function_runtime        = var.function_runtime
  function_runtime_version = var.function_runtime_version
  function_app_client_id  = module.identity.apim_api_application_id

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

module "apim" {
  source = "../../modules/apim"

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
  apim_api_audience             = module.identity.apim_api_identifier_uri
  foundry_agent_client_id       = module.identity.foundry_agent_application_id
  log_analytics_workspace_id    = module.monitoring.log_analytics_workspace_id

  tags = var.tags

  depends_on = [module.function_app]
}

module "webapp" {
  source = "../../modules/webapp"

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
