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

variable "function_app_plan_sku" {
  description = "SKU for Function App Service Plan"
  type        = string
  default     = "B1"  # Use EP1 or higher for production
}

variable "function_runtime" {
  description = "Function runtime (python, node, dotnet, etc.)"
  type        = string
  default     = "python"
}

variable "function_runtime_version" {
  description = "Function runtime version"
  type        = string
  default     = "3.11"
}

variable "always_on" {
  description = "Enable Always On for Function App"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins for Function App"
  type        = list(string)
  default     = []
}

variable "application_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
}

variable "functions_pe_subnet_id" {
  description = "Subnet ID for Function App private endpoints"
  type        = string
}

variable "storage_pe_subnet_id" {
  description = "Subnet ID for Storage Account private endpoints"
  type        = string
}

variable "private_dns_zone_azurewebsites_id" {
  description = "Private DNS zone ID for Azure Websites"
  type        = string
}

variable "private_dns_zone_blob_id" {
  description = "Private DNS zone ID for Storage Blob"
  type        = string
}

variable "private_dns_zone_file_id" {
  description = "Private DNS zone ID for Storage File"
  type        = string
}

variable "private_dns_zone_queue_id" {
  description = "Private DNS zone ID for Storage Queue"
  type        = string
}

variable "private_dns_zone_table_id" {
  description = "Private DNS zone ID for Storage Table"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
