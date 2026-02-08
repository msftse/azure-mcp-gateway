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

variable "foundry_agent_principal_id" {
  description = "Principal ID (object ID) of the Foundry Agent's Managed Identity"
  type        = string
  default     = ""
}

variable "create_user_assigned_mi" {
  description = "Create optional user-assigned managed identity"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
