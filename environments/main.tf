###############################################################
# Root Module — azure-policy-exemption-workflow
#
# Wires all three child modules together:
#   1. policy-assignments  → policies at Management Group scope
#   2. governance-infrastructure → Logic App approval engine
#   3. monitoring          → expiry alerts and audit
#
# Provider and Terraform version config: see providers.tf
# GitHub: https://github.com/infantusgodfrey/azure-policy-exemption-workflow
###############################################################

###############################################################
# Local: resolve allowed VM SKU list
# Falls back to module default when var.allowed_vm_skus is empty
###############################################################
locals {
  resolved_vm_skus = length(var.allowed_vm_skus) > 0 ? var.allowed_vm_skus : [
    "Standard_D2s_v3",
    "Standard_D4s_v3",
    "Standard_D8s_v3",
    "Standard_E2s_v3",
    "Standard_E4s_v3",
    "Standard_B2s",
    "Standard_B4ms"
  ]
}

###############################################################
# Module 1: policy-assignments
# Assigns 3 policies at Management Group scope
###############################################################
module "policy_assignments" {
  source = "../modules/policy-assignments"

  management_group_id = var.management_group_id
  allowed_vm_skus     = local.resolved_vm_skus
  tags                = var.tags
}

###############################################################
# Module 2: governance-infrastructure
# Deploys Logic App approval engine with Managed Identity RBAC
###############################################################
module "governance_infrastructure" {
  source = "../modules/governance-infrastructure"

  location                   = var.location
  management_group_id        = var.management_group_id
  governance_subscription_id = var.governance_subscription_id
  approver_email             = var.approver_email
  log_retention_days         = var.log_retention_days
  tags                       = var.tags
}

###############################################################
# Module 3: monitoring
# Expiry alert — wired to governance-infrastructure outputs
###############################################################
module "monitoring" {
  source = "../modules/monitoring"

  governance_subscription_id     = var.governance_subscription_id
  governance_resource_group_name = module.governance_infrastructure.governance_resource_group_name
  log_analytics_workspace_id     = module.governance_infrastructure.log_analytics_workspace_id
  approver_email                 = var.approver_email
  location                       = var.location
  expiry_alert_days              = var.expiry_alert_days
  tags                           = var.tags

  depends_on = [module.governance_infrastructure]
}
