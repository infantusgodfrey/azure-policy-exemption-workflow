variable "governance_subscription_id" {
  description = "Subscription ID where governance resources are deployed"
  type        = string
}

variable "governance_resource_group_name" {
  description = "Resource group name for governance resources — sourced from governance-infrastructure module output"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID — sourced from governance-infrastructure module output"
  type        = string
}

variable "approver_email" {
  description = "Email address for expiry alert notifications"
  type        = string
}

variable "location" {
  description = "Azure region for monitoring resources"
  type        = string
  default     = "eastus"
}

variable "expiry_alert_days" {
  description = "Alert fires when an exemption will expire within this many days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}
