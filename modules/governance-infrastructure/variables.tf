variable "location" {
  description = "Azure region for all governance resources"
  type        = string
  default     = "eastus"
}

variable "management_group_id" {
  description = "Management Group ID — the Logic App Managed Identity is granted Resource Policy Contributor at this scope, enabling cross-subscription exemption creation"
  type        = string
}

variable "governance_subscription_id" {
  description = "Subscription ID where governance resources (Logic App, Log Analytics) are deployed"
  type        = string
}

variable "approver_email" {
  description = "Email address or distribution list of the central governance / approval team"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain audit logs in the Log Analytics Workspace"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to all resources created by this module"
  type        = map(string)
  default = {
    Environment = "governance"
    ManagedBy   = "Terraform"
    Purpose     = "Central policy exemption approval engine"
  }
}
