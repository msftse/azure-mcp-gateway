# Example dev.tfvars for dev environment
# Copy this file to dev.tfvars and fill in your values
# DO NOT commit dev.tfvars to source control
# Usage: terraform plan -var-file="dev.tfvars"

# Azure Configuration
subscription_id = "df5106e8-5b00-46cc-be36-6f8b3032d5a4"
tenant_id       = "f6bf2550-3953-43ff-b71b-c4b8b4553452"
location        = "swedencentral"
environment     = "dev"
project_name    = "mcpgw"

# APIM Publisher Information
apim_publisher_name  = "MCP Gateway"
apim_publisher_email = "itzhakjanach@microsoft.com"

# Foundry Agent Configuration
# Provide the Principal ID (object ID) of the Foundry Agent's Managed Identity
# Leave empty to allow any managed identity (less secure, for dev/testing only)
foundry_agent_principal_id = ""  # Or "<foundry-agent-principal-id>"

# Optional: Foundry Endpoint
# foundry_endpoint = "https://yourfoundry.endpoint.com"

# Tags
tags = {
  Environment = "dev"
  Project     = "Azure MCP Gateway"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
