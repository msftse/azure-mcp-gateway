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

variable "create_foundry_agent" {
  description = "Create new Foundry Agent app registration"
  type        = bool
  default     = true
}

variable "foundry_agent_client_id" {
  description = "Existing Foundry Agent client ID (if not creating new)"
  type        = string
  default     = null
}

variable "create_user_assigned_mi" {
  description = "Create user-assigned managed identity for APIM"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
