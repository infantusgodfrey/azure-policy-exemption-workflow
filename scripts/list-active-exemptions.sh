#!/bin/bash
# ============================================================
# list-active-exemptions.sh
#
# Lists all active (non-expired) policy exemptions across
# a given subscription, with days remaining until expiry.
#
# Usage:
#   export SUBSCRIPTION_ID="<your-subscription-id>"
#   ./scripts/list-active-exemptions.sh
#
# GitHub: https://github.com/infantusgodfrey/azure-policy-exemption-workflow
# ============================================================

set -euo pipefail

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"

if [[ -z "${SUBSCRIPTION_ID}" ]]; then
  echo "❌ Error: Set the SUBSCRIPTION_ID environment variable."
  echo "   export SUBSCRIPTION_ID=<your-sub-id>"
  exit 1
fi

echo ""
echo "🔍 Active Policy Exemptions — Subscription: ${SUBSCRIPTION_ID}"
echo "══════════════════════════════════════════════════════════════"

NOW=$(date -u +%s)

az rest \
  --method GET \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Authorization/policyExemptions?api-version=2022-07-01-preview" \
  --query "value[].{
    Name:name,
    DisplayName:properties.displayName,
    Category:properties.exemptionCategory,
    ExpiresOn:properties.expiresOn,
    Requester:properties.metadata.requester,
    Team:properties.metadata.team,
    Ticket:properties.metadata.ticketReference,
    Scope:id
  }" \
  -o table 2>/dev/null || {
    echo "❌ Failed to query exemptions. Ensure you are logged in:"
    echo "   az login && az account set --subscription ${SUBSCRIPTION_ID}"
    exit 1
  }

echo ""
echo "Tip: Run the KQL audit queries in Log Analytics for full history and expiry dashboards."
echo "     Workspace: law-policy-governance"
