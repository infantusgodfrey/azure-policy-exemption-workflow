###############################################################
# Module: governance-infrastructure
#
# Deploys the central approval engine for policy exemptions:
#   - Resource Group
#   - Storage Account (Logic App dependency)
#   - Log Analytics Workspace (audit trail)
#   - Logic App Workflow (system-assigned Managed Identity)
#   - RBAC: Resource Policy Contributor at Management Group scope
#   - Office 365 API Connection (requires manual OAuth after deploy)
#   - Logic App Workflow Definition (ARM template injection)
#   - Diagnostic Settings (Logic App → Log Analytics)
#
# After apply: Authorize the Office 365 connection in Azure
# Portal → API Connections → office365-connection → Edit → Authorize
###############################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

locals {
  mg_scope           = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  logic_app_name     = "la-policy-exemption-approval"
  o365_conn_name     = "office365-connection"
  law_name           = "law-policy-governance"
  storage_acct_name  = "stpolicyexempt${random_string.suffix.result}"
}

###############################################################
# Resource Group
###############################################################
resource "azurerm_resource_group" "governance" {
  name     = "rg-policy-governance"
  location = var.location
  tags     = var.tags
}

###############################################################
# Storage Account — Required by Logic App (Consumption tier)
###############################################################
resource "azurerm_storage_account" "logic_app" {
  name                            = local.storage_acct_name
  resource_group_name             = azurerm_resource_group.governance.name
  location                        = azurerm_resource_group.governance.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

###############################################################
# Log Analytics Workspace — Audit trail for all exemptions
###############################################################
resource "azurerm_log_analytics_workspace" "governance" {
  name                = local.law_name
  resource_group_name = azurerm_resource_group.governance.name
  location            = azurerm_resource_group.governance.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

###############################################################
# Logic App Workflow — System-assigned Managed Identity
# No credentials stored — uses MSI for Azure REST API calls
###############################################################
resource "azurerm_logic_app_workflow" "exemption_approval" {
  name                = local.logic_app_name
  resource_group_name = azurerm_resource_group.governance.name
  location            = azurerm_resource_group.governance.location

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      parameters,
      workflow_parameters,
    ]
  }

  tags = var.tags
}

###############################################################
# RBAC — Logic App Managed Identity at Management Group scope
#
# Resource Policy Contributor: create/delete policy exemptions
# Reader: validate resource scope exists before exemption
#
# Management Group scope = cross-subscription coverage
# (no per-subscription role assignments needed)
###############################################################
resource "azurerm_role_assignment" "logic_app_policy_contributor" {
  scope                = local.mg_scope
  role_definition_name = "Resource Policy Contributor"
  principal_id         = azurerm_logic_app_workflow.exemption_approval.identity[0].principal_id
  depends_on           = [azurerm_logic_app_workflow.exemption_approval]
}

resource "azurerm_role_assignment" "logic_app_reader" {
  scope                = local.mg_scope
  role_definition_name = "Reader"
  principal_id         = azurerm_logic_app_workflow.exemption_approval.identity[0].principal_id
  depends_on           = [azurerm_logic_app_workflow.exemption_approval]
}

###############################################################
# Office 365 API Connection
#
# ⚠️  MANUAL STEP REQUIRED AFTER APPLY:
# Portal → rg-policy-governance → office365-connection
# → Edit API connection → Authorize → Save
#
# This OAuth step cannot be automated via Terraform.
# It is a one-time action per deployment.
###############################################################
resource "azurerm_resource_group_template_deployment" "o365_connection" {
  name                = "office365-api-connection"
  resource_group_name = azurerm_resource_group.governance.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    resources = [
      {
        type       = "Microsoft.Web/connections"
        apiVersion = "2016-06-01"
        name       = local.o365_conn_name
        location   = var.location
        properties = {
          displayName = "Governance Team - Office 365"
          api = {
            id = "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', '${var.location}', '/managedApis/office365')]"
          }
        }
      }
    ]
  })

  depends_on = [azurerm_resource_group.governance]
}

###############################################################
# Logic App Workflow Definition (ARM Template)
# Injects the full workflow JSON from templates/
###############################################################
resource "azurerm_resource_group_template_deployment" "logic_app_definition" {
  name                = "logic-app-workflow-definition"
  resource_group_name = azurerm_resource_group.governance.name
  deployment_mode     = "Incremental"

  template_content = file("${path.module}/templates/logic_app_definition.json")

  parameters_content = jsonencode({
    logicAppName            = { value = local.logic_app_name }
    location                = { value = var.location }
    approverEmail           = { value = var.approver_email }
    office365ConnectionName = { value = local.o365_conn_name }
    subscriptionId          = { value = var.governance_subscription_id }
    resourceGroupName       = { value = azurerm_resource_group.governance.name }
  })

  depends_on = [
    azurerm_logic_app_workflow.exemption_approval,
    azurerm_resource_group_template_deployment.o365_connection,
    azurerm_role_assignment.logic_app_policy_contributor,
  ]
}

###############################################################
# Diagnostic Settings — Logic App runs → Log Analytics
###############################################################
resource "azurerm_monitor_diagnostic_setting" "logic_app" {
  name                       = "diag-logic-app-to-law"
  target_resource_id         = azurerm_logic_app_workflow.exemption_approval.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.governance.id

  enabled_log {
    category = "WorkflowRuntime"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
