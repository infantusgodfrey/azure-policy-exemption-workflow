###############################################################
# Module: policy-assignments
#
# Assigns three enterprise-grade Azure Policies at Management
# Group scope so they cover every child subscription.
#
# Policies:
#   1. Deny Public Blob Access on Storage Accounts
#   2. Require 'Environment' Tag on Resource Groups
#   3. Restrict VM SKUs to an Approved List
#
# All exemptions to these policies must go through the
# central approval workflow (module: governance-infrastructure)
###############################################################

locals {
  mg_scope = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
}

###############################################################
# POLICY 1 — Deny Public Blob Access on Storage Accounts
# Built-in Policy ID: 4fa4b6c0-31ca-4c0d-b10d-24b96f62a751
###############################################################
resource "azurerm_management_group_policy_assignment" "deny_public_blob" {
  name                 = "deny-public-blob-access"
  display_name         = "Deny Public Blob Access on Storage Accounts"
  management_group_id  = local.mg_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/4fa4b6c0-31ca-4c0d-b10d-24b96f62a751"
  enforce              = true

  description = "Blocks anonymous public read access on storage account blob containers. Exemptions must be approved via the central governance workflow."

  non_compliance_message {
    content = "Public blob access is prohibited by company policy. Submit an exemption request: run ./scripts/request-exemption.sh"
  }
}

###############################################################
# POLICY 2 — Require 'Environment' Tag on Resource Groups
# Built-in Policy ID: 96670d01-0a4d-4649-9c89-2d3abc0a5025
###############################################################
resource "azurerm_management_group_policy_assignment" "require_environment_tag" {
  name                 = "require-environment-tag"
  display_name         = "Require 'Environment' Tag on Resource Groups"
  management_group_id  = local.mg_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  enforce              = true

  description = "All resource groups must carry an 'Environment' tag (dev/staging/prod). Exemption required for third-party-managed resource groups."

  parameters = jsonencode({
    tagName = { value = "Environment" }
  })

  non_compliance_message {
    content = "Resource groups must have an 'Environment' tag. Request a tagging exemption via the central workflow."
  }
}

###############################################################
# POLICY 3 — Restrict VM SKUs to an Approved List
# Built-in Policy ID: cccc23c7-8427-4f53-ad12-b6a63eb452b3
###############################################################
resource "azurerm_management_group_policy_assignment" "allowed_vm_skus" {
  name                 = "restrict-vm-skus"
  display_name         = "Restrict Virtual Machine SKUs to Approved List"
  management_group_id  = local.mg_scope
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
  enforce              = true

  description = "Only cost-optimized, approved VM SKUs may be deployed. PoC teams must request exemptions for non-standard SKUs."

  parameters = jsonencode({
    listOfAllowedSKUs = {
      value = var.allowed_vm_skus
    }
  })

  non_compliance_message {
    content = "This VM SKU is not on the approved list. PoC teams: submit an exemption request with your use case and expected duration."
  }
}
