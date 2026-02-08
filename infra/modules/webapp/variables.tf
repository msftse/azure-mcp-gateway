variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "webapp_sku" {
  description = "SKU for Web App Service Plan"
  type        = string
  default     = "B1"
}

variable "node_version" {
  description = "Node.js version for the web app"
  type        = string
  default     = "18"
}

variable "always_on" {
  description = "Enable Always On for Web App"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins for Web App"
  type        = list(string)
  default     = []
}

variable "foundry_endpoint" {
  description = "Azure AI Foundry endpoint URL"
  type        = string
  default     = ""
}

variable "application_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
}

variable "webapp_integration_subnet_id" {
  description = "Subnet ID for Web App VNet integration"
  type        = string
}

variable "functions_pe_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}

variable "private_dns_zone_azurewebsites_id" {
  description = "Private DNS zone ID for Azure Websites"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
