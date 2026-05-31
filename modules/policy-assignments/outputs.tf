output "deny_public_blob_assignment_id" {
  description = "Full Policy Assignment ID for 'Deny Public Blob Access'. Use this value in exemption requests targeting storage accounts."
  value       = azurerm_management_group_policy_assignment.deny_public_blob.id
}

output "require_environment_tag_assignment_id" {
  description = "Full Policy Assignment ID for 'Require Environment Tag'. Use this value in exemption requests targeting resource groups."
  value       = azurerm_management_group_policy_assignment.require_environment_tag.id
}

output "allowed_vm_skus_assignment_id" {
  description = "Full Policy Assignment ID for 'Restrict VM SKUs'. Use this value in exemption requests targeting virtual machines."
  value       = azurerm_management_group_policy_assignment.allowed_vm_skus.id
}

output "management_group_scope" {
  description = "The Management Group ARM scope where all policies are assigned"
  value       = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
}
