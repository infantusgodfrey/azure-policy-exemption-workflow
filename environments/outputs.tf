###############################################################
# Root Module Outputs
# Run: terraform output -json  for full summary after apply
###############################################################

output "policy_assignment_ids" {
  description = "Policy Assignment IDs — use these values in exemption request payloads"
  value = {
    deny_public_blob       = module.policy_assignments.deny_public_blob_assignment_id
    require_environment_tag = module.policy_assignments.require_environment_tag_assignment_id
    allowed_vm_skus        = module.policy_assignments.allowed_vm_skus_assignment_id
  }
}

output "logic_app_name" {
  description = "Logic App workflow name"
  value       = module.governance_infrastructure.logic_app_name
}

output "logic_app_managed_identity_object_id" {
  description = "Managed Identity Object ID — verify RBAC assignments in Portal"
  value       = module.governance_infrastructure.logic_app_managed_identity_object_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID"
  value       = module.governance_infrastructure.log_analytics_workspace_id
}

output "governance_resource_group" {
  description = "Resource group containing all governance resources"
  value       = module.governance_infrastructure.governance_resource_group_name
}

output "get_trigger_url_command" {
  description = "Run this command to retrieve the Logic App HTTP trigger URL (keep it secret — treat like a password)"
  value       = module.governance_infrastructure.trigger_url_command
}

output "next_steps" {
  description = "Post-deployment checklist"
  value = {
    step_1 = "Authorize the Office 365 API connection: Portal → rg-policy-governance → office365-connection → Edit → Authorize"
    step_2 = "Retrieve the Logic App trigger URL: run the command in 'get_trigger_url_command' output"
    step_3 = "Set the trigger URL as env var: export POLICY_EXEMPTION_TRIGGER_URL=<url>"
    step_4 = "Submit a test exemption: ./scripts/request-exemption.sh"
    step_5 = "Check the governance team inbox for the approval email"
  }
}
