output "logic_app_name" {
  description = "Name of the deployed Logic App workflow"
  value       = azurerm_logic_app_workflow.exemption_approval.name
}

output "logic_app_id" {
  description = "Full ARM resource ID of the Logic App"
  value       = azurerm_logic_app_workflow.exemption_approval.id
}

output "logic_app_managed_identity_object_id" {
  description = "Object ID of the Logic App's system-assigned Managed Identity. Use this to verify RBAC assignments in the Portal."
  value       = azurerm_logic_app_workflow.exemption_approval.identity[0].principal_id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace — pass this to the monitoring module"
  value       = azurerm_log_analytics_workspace.governance.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.governance.name
}

output "governance_resource_group_name" {
  description = "Name of the governance resource group — pass this to the monitoring module"
  value       = azurerm_resource_group.governance.name
}

output "trigger_url_command" {
  description = "Run this command to retrieve the Logic App HTTP trigger URL (the exemption submission endpoint)"
  value       = "az rest --method POST --uri 'https://management.azure.com${azurerm_logic_app_workflow.exemption_approval.id}/triggers/Exemption_Request_Received/listCallbackUrl?api-version=2019-05-01'"
}
