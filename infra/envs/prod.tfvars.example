# Example prod.tfvars for production environment
# Copy this file to prod.tfvars and fill in your values
# DO NOT commit prod.tfvars to source control
# Usage: terraform plan -var-file="prod.tfvars"

# Azure Configuration
subscription_id = "<your-subscription-id>"
tenant_id       = "<your-tenant-id>"
location        = "swedencentral"
environment     = "prod"
project_name    = "mcpgw"

# APIM Publisher Information
apim_publisher_name  = "Your Organization"
apim_publisher_email = "admin@yourorg.com"

# Production SKUs
apim_sku_name         = "Premium_1"  # Premium for VNet + zone redundancy
function_app_plan_sku = "EP1"        # Elastic Premium
webapp_sku            = "P1v3"       # Production App Service tier

# Foundry Agent Configuration
# REQUIRED: Provide the Principal ID (object ID) of your Foundry Agent's Managed Identity
foundry_agent_principal_id = "<your-foundry-agent-principal-id>"

# Optional: Foundry Endpoint
foundry_endpoint = "https://yourfoundry.endpoint.com"

# Enhanced Security
enable_nsgs = true
log_retention_days = 90  # Longer retention for compliance

# Tags
tags = {
  Environment = "prod"
  Project     = "Azure MCP Gateway"
  ManagedBy   = "Terraform"
  CostCenter  = "Production"
  Criticality = "High"
}
