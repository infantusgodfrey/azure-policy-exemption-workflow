###############################################################
# Root Module Variables
# Copy terraform.tfvars.example → terraform.tfvars and fill in.
###############################################################

variable "management_group_id" {
  description = "Root Management Group ID (not the display name — the actual ID, e.g. 'mg-contoso-root')"
  type        = string
}

variable "governance_subscription_id" {
  description = "Subscription ID where Logic App, Log Analytics, and monitoring resources are deployed"
  type        = string
}

variable "dev_subscription_id" {
  description = "Dev team subscription ID (used for validation in the walkthrough)"
  type        = string
}

variable "location" {
  description = "Primary Azure region for all deployments"
  type        = string
  default     = "eastus"
}

variable "approver_email" {
  description = "Governance team email address or distribution list for approval emails and expiry alerts"
  type        = string
}

variable "log_retention_days" {
  description = "Days to retain audit logs in Log Analytics"
  type        = number
  default     = 90
}

variable "expiry_alert_days" {
  description = "Alert fires this many days before an exemption expires"
  type        = number
  default     = 7
}

variable "allowed_vm_skus" {
  description = "Override the default approved VM SKU list if needed"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources across all modules"
  type        = map(string)
  default = {
    Project   = "azure-policy-exemption-workflow"
    ManagedBy = "Terraform"
    Repo      = "https://github.com/infantusgodfrey/azure-policy-exemption-workflow"
  }
}
