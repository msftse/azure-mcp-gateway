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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "publisher_name" {
  description = "Publisher name for APIM"
  type        = string
}

variable "publisher_email" {
  description = "Publisher email for APIM"
  type        = string
}

variable "sku_name" {
  description = "SKU for APIM (Developer_1, Basic_1, Standard_1, Premium_1)"
  type        = string
  default     = "Developer_1"
}

variable "apim_subnet_id" {
  description = "Subnet ID for APIM VNet integration"
  type        = string
}

variable "function_app_id" {
  description = "ID of the Function App"
  type        = string
}

variable "function_app_hostname" {
  description = "Hostname of the Function App"
  type        = string
}

variable "apim_api_audience" {
  description = "Audience for APIM API (e.g., api://apim-api-identifier)"
  type        = string
}

variable "foundry_agent_client_id" {
  description = "Client ID of the Foundry Agent"
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
