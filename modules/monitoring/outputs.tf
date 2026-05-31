output "action_group_id" {
  description = "Resource ID of the governance alert Action Group"
  value       = azurerm_monitor_action_group.governance.id
}

output "expiry_alert_rule_id" {
  description = "Resource ID of the exemption expiry scheduled query alert"
  value       = azurerm_monitor_scheduled_query_rules_alert_v2.expiring_exemptions.id
}
