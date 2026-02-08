# Azure Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "swedencentral"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mcpgw"
}

# Networking
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "apim_subnet_address_prefix" {
  description = "Address prefix for APIM subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "functions_pe_subnet_address_prefix" {
  description = "Address prefix for Functions private endpoint subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "webapp_integration_subnet_address_prefix" {
  description = "Address prefix for Web App integration subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "storage_pe_subnet_address_prefix" {
  description = "Address prefix for Storage private endpoint subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "enable_nsgs" {
  description = "Enable Network Security Groups"
  type        = bool
  default     = true
}

# Monitoring
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "disable_ip_masking" {
  description = "Disable IP masking in Application Insights"
  type        = bool
  default     = false
}

# Identity
variable "foundry_agent_principal_id" {
  description = "Principal ID (object ID) of the Foundry Agent's Managed Identity"
  type        = string
  default     = ""
}

# APIM
variable "apim_sku_name" {
  description = "SKU for APIM"
  type        = string
  default     = "Developer_1"
}

variable "apim_publisher_name" {
  description = "Publisher name for APIM"
  type        = string
}

variable "apim_publisher_email" {
  description = "Publisher email for APIM"
  type        = string
}

# Function App
variable "function_app_plan_sku" {
  description = "SKU for Function App Service Plan"
  type        = string
  default     = "B1"
}

variable "function_runtime" {
  description = "Function runtime"
  type        = string
  default     = "python"
}

variable "function_runtime_version" {
  description = "Function runtime version"
  type        = string
  default     = "3.11"
}

# Web App
variable "webapp_sku" {
  description = "SKU for Web App Service Plan"
  type        = string
  default     = "B1"
}

variable "node_version" {
  description = "Node.js version for the web app"
  type        = string
  default     = "18-lts"
}

variable "foundry_endpoint" {
  description = "Azure AI Foundry endpoint URL"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
