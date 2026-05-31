###############################################################
# Module: monitoring
#
# Deploys expiry alerting and audit infrastructure:
#   - Action Group (who gets notified)
#   - Scheduled Query Alert (exemptions expiring in N days)
#
# KQL query scans Azure Activity Log for policy exemptions
# with expiresOn within the configured window and fires
# an email alert to the governance team.
###############################################################

###############################################################
# Action Group — Notification target for all alerts
###############################################################
resource "azurerm_monitor_action_group" "governance" {
  name                = "ag-policy-governance-alerts"
  resource_group_name = var.governance_resource_group_name
  short_name          = "gov-alerts"

  email_receiver {
    name                    = "GovernanceTeam"
    email_address           = var.approver_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

###############################################################
# Scheduled Query Alert — Exemptions expiring within N days
#
# Runs daily via KQL against the Log Analytics Workspace.
# Fires if any exemption's expiresOn falls within the window.
# Severity 2 = Warning (actionable, not critical)
###############################################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "expiring_exemptions" {
  name                    = "alert-policy-exemptions-expiring-${var.expiry_alert_days}d"
  resource_group_name     = var.governance_resource_group_name
  location                = var.location
  description             = "Fires when any active Azure Policy exemption will expire within ${var.expiry_alert_days} days. Take action: renew or let lapse."
  display_name            = "Policy Exemptions Expiring Within ${var.expiry_alert_days} Days"
  severity                = 2
  enabled                 = true
  auto_mitigation_enabled = false
  evaluation_frequency    = "P1D"
  window_duration         = "P1D"

  scopes = [var.log_analytics_workspace_id]

  criteria {
    query = <<-KQL
      AzureActivity
      | where OperationNameValue == "Microsoft.Authorization/policyExemptions/write"
      | where ActivityStatusValue == "Success"
      | extend Props        = parse_json(Properties)
      | extend Body         = parse_json(tostring(Props.requestbody))
      | extend ExpiresOn    = todatetime(tostring(Body.properties.expiresOn))
      | extend ExemptionName = tostring(Body.properties.displayName)
      | extend Requester    = tostring(parse_json(tostring(Body.properties.metadata)).requester)
      | extend Team         = tostring(parse_json(tostring(Body.properties.metadata)).team)
      | extend TicketRef    = tostring(parse_json(tostring(Body.properties.metadata)).ticketReference)
      | where ExpiresOn between (now() .. now() + ${var.expiry_alert_days}d)
      | project TimeGenerated, ExemptionName, ExpiresOn, DaysRemaining = datetime_diff('day', ExpiresOn, now()), Requester, Team, TicketRef, ResourceId
      | order by ExpiresOn asc
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.governance.id]
  }

  tags = var.tags
}
