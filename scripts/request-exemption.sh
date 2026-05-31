#!/bin/bash
# ============================================================
# request-exemption.sh
#
# Submit a policy exemption request to the central
# governance approval workflow.
#
# Prerequisites:
#   export POLICY_EXEMPTION_TRIGGER_URL="<logic-app-trigger-url>"
#
# Get the trigger URL after terraform apply:
#   terraform -chdir=environments output -raw get_trigger_url_command | bash
#
# GitHub: https://github.com/infantusgodfrey/azure-policy-exemption-workflow
# ============================================================

set -euo pipefail

# ── Validate prerequisites ──────────────────────────────────
if [[ -z "${POLICY_EXEMPTION_TRIGGER_URL:-}" ]]; then
  echo "❌ Error: POLICY_EXEMPTION_TRIGGER_URL environment variable is not set."
  echo ""
  echo "   Retrieve it after terraform apply:"
  echo "   terraform -chdir=environments output -raw get_trigger_url_command | bash"
  exit 1
fi

# ── Configure your exemption request ───────────────────────
# Edit these values for your specific request

REQUESTER_NAME="John Smith"
REQUESTER_EMAIL="john.smith@company.com"
TEAM_NAME="Payments Dev Team"
TICKET="JIRA-4521"
DURATION_DAYS=14

# Scope: ARM resource ID of the specific resource to exempt
# Tightest possible scope = best practice
DEV_SUB_ID="${DEV_SUBSCRIPTION_ID:-<your-dev-sub-id>}"
RESOURCE_GROUP="rg-payments-dev"
STORAGE_ACCOUNT="stpaymentsdev001"

RESOURCE_SCOPE="/subscriptions/${DEV_SUB_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT}"

# Policy assignment ID — from: terraform -chdir=environments output policy_assignment_ids
MG_ID="${MANAGEMENT_GROUP_ID:-<your-mg-id>}"
POLICY_ASSIGNMENT_ID="/providers/Microsoft.Management/managementGroups/${MG_ID}/providers/Microsoft.Authorization/policyAssignments/deny-public-blob-access"

# Unique, descriptive exemption name (no spaces, max 64 chars)
EXEMPTION_NAME="waiver-stpaymentsdev001-publicblob-$(date +%Y%m%d)"

JUSTIFICATION="Partner API integration (PartnerCo) requires public read access on container 'partner-uploads' during integration testing phase. Will migrate to SAS token auth upon test completion. Ref: ADR-112."

# ── Submit ──────────────────────────────────────────────────
echo ""
echo "📤 Submitting Policy Exemption Request"
echo "══════════════════════════════════════════"
echo "  Requester  : ${REQUESTER_NAME} (${REQUESTER_EMAIL})"
echo "  Team       : ${TEAM_NAME}"
echo "  Ticket     : ${TICKET}"
echo "  Resource   : ${STORAGE_ACCOUNT}"
echo "  Duration   : ${DURATION_DAYS} days"
echo "  Exemption  : ${EXEMPTION_NAME}"
echo ""

HTTP_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
  "${POLICY_EXEMPTION_TRIGGER_URL}" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "requester_name":       "${REQUESTER_NAME}",
  "requester_email":      "${REQUESTER_EMAIL}",
  "team_name":            "${TEAM_NAME}",
  "exemption_name":       "${EXEMPTION_NAME}",
  "resource_scope":       "${RESOURCE_SCOPE}",
  "policy_assignment_id": "${POLICY_ASSIGNMENT_ID}",
  "policy_display_name":  "Deny Public Blob Access on Storage Accounts",
  "justification":        "${JUSTIFICATION}",
  "duration_days":        ${DURATION_DAYS},
  "ticket_reference":     "${TICKET}"
}
EOF
)

HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "${HTTP_RESPONSE}" | sed '/HTTP_STATUS/d')

if [[ "${HTTP_STATUS}" == "202" ]]; then
  echo "✅ Request submitted successfully (HTTP 202)"
  echo ""
  echo "Response:"
  echo "${BODY}" | python3 -m json.tool 2>/dev/null || echo "${BODY}"
  echo ""
  echo "📧 The governance team has been notified."
  echo "   Watch your inbox — you'll be emailed once a decision is made."
else
  echo "❌ Submission failed (HTTP ${HTTP_STATUS})"
  echo ""
  echo "${BODY}"
  exit 1
fi
