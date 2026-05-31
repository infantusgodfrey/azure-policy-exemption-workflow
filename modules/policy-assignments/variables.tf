variable "management_group_id" {
  description = "Management Group ID where all policies are assigned (covers all child subscriptions)"
  type        = string
}

variable "allowed_vm_skus" {
  description = "List of approved VM SKUs permitted across all subscriptions under the management group"
  type        = list(string)
  default = [
    "Standard_D2s_v3",
    "Standard_D4s_v3",
    "Standard_D8s_v3",
    "Standard_E2s_v3",
    "Standard_E4s_v3",
    "Standard_B2s",
    "Standard_B4ms"
  ]
}

variable "tags" {
  description = "Tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}
