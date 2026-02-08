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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
