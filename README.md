<div align="center">

# 🛡️ Azure Cross-Subscription Policy Exemption Workflow

**A production-ready, auditable exemption engine for Azure Policy — built with Terraform + Azure Logic Apps**

[![Terraform](https://img.shields.io/badge/Terraform-~>%201.15-7B42BC?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Policy%20Exemptions-0078D4?logo=microsoftazure)](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/exemption-structure)

<br/>

**If this repo helped you, please ⭐ Star it — it helps others find it.**

[📖 Read the Full Article on Medium](#) · [🍴 Fork this Repo](https://github.com/infantusgodfrey/azure-policy-exemption-workflow/fork) · [🐛 Report an Issue](https://github.com/infantusgodfrey/azure-policy-exemption-workflow/issues)

</div>

---

## The Problem

Enterprise Azure environments use Azure Policy to enforce compliance at scale. But real teams constantly need **legitimate, time-bound exceptions**:

- A dev team needs a public endpoint for 2 weeks to test a partner API integration
- A legacy application cannot yet meet a new encryption standard during migration
- A PoC uses a non-approved VM SKU for 30 days before a production decision

The naive responses — *"no exceptions ever"* (kills agility) or *"just disable the policy"* (kills governance) — both fail in practice.

**This repo gives you a third option**: a formal, auditable, time-bound exemption workflow where every approval is a click, every exemption auto-expires, and every decision lands in the Activity Log.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      Root Management Group                       │
│            (Azure Policies assigned here — all subs)             │
├─────────────────────────┬────────────────────────────────────────┤
│    Dev Subscription     │          Prod Subscription             │
│  ┌──────────────────┐   │   ┌──────────────────────┐             │
│  │  Storage Account │   │   │   Virtual Machine    │             │
│  │  [DENIED ❌]     │   │   │   [DENIED ❌]       │             │
│  └──────────────────┘   │   └──────────────────────┘             │
└─────────────────────────┴────────────────────────────────────────┘
         │  1. Submit request                  ▲ 4. Exemption created
         ▼                                     │    (scoped + time-bound)
┌──────────────────────────────────────────────────────────────────┐
│                    Governance Subscription                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │      Logic App  (la-policy-exemption-approval)             │  │
│  │                                                            │  │
│  │  [HTTP Trigger] → [Approval Email] → [Condition]           │  │
│  │                        ↓                  ↓                │  │
│  │                2. Governance     Approved → REST API call  │  │
│  │                   Team Email     Rejected → Notify         │  │
│  │                   [Approve/Reject]                         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────┐   ┌────────────────────────────────┐   │
│  │  Log Analytics (KQL) │   │  Azure Monitor (Expiry Alerts) │   │
│  └──────────────────────┘   └────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Purpose |
|---|---|
| **Azure Policy** | Enforce compliance across all subscriptions |
| **Azure Logic Apps** | Approval workflow — pause, notify, resume |
| **Office 365 Connector** | Email with Approve/Reject buttons |
| **Managed Identity** | Logic App calls Azure REST API — no stored credentials |
| **Terraform Modules** | All infrastructure as code, modular and reusable |
| **Azure Monitor + KQL** | Expiry alerts and full audit trail |

---

## Repository Structure

```
azure-policy-exemption-workflow/
├── modules/
│   ├── policy-assignments/          # 3 policies at Management Group scope
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── governance-infrastructure/   # Logic App + RBAC + Log Analytics
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── templates/
│   │       └── logic_app_definition.json
│   │
│   └── monitoring/                  # Expiry alerts via Azure Monitor
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/                    # Root module — wires everything together
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── scripts/
│   ├── request-exemption.sh         # Submit an exemption request
│   └── list-active-exemptions.sh    # Query active exemptions in a subscription
│
├── .github/
│   └── workflows/
│       └── terraform-validate.yml   # CI: format check + validate all modules
│
└── README.md
```

---

## Prerequisites

- [ ] Azure CLI ≥ 2.50: `az --version`
- [ ] Terraform ≥ 1.6: `terraform --version`
- [ ] **Owner** or **User Access Administrator** on your root Management Group
- [ ] Three subscriptions: `governance`, `dev`, `prod`
- [ ] Office 365 account for the Logic App email connector

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/infantusgodfrey/azure-policy-exemption-workflow.git
cd azure-policy-exemption-workflow

# 2. Configure your values
cd environments
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription IDs, MG ID, and approver email

# 3. Deploy everything
terraform init
terraform plan
terraform apply

# 4. Get the Logic App trigger URL (your submission endpoint)
terraform output -raw get_trigger_url_command | bash

# 5. Authorize the Office 365 connection (one-time manual step)
# Portal → rg-policy-governance → office365-connection → Edit → Authorize

# 6. Submit a test exemption request
cd ..
export POLICY_EXEMPTION_TRIGGER_URL="<url-from-step-4>"
./scripts/request-exemption.sh
```

---

## What Happens After You Submit a Request

1. **Your team** runs `./scripts/request-exemption.sh` → HTTP 202 returned immediately
2. **Governance team** receives an email with full request details + **[Approve] [Reject]** buttons
3. On **Approve** → Logic App calls Azure REST API → Policy Exemption created with `expiresOn` date
4. **You** receive a confirmation email with the exemption name and expiry date
5. On **Reject** → You receive a rejection email with next steps
6. **Azure Monitor** fires an alert 7 days before any exemption expires
7. All of it lands in **Azure Activity Log** — auditable forever

---

## KQL Audit Queries

Run these in **Log Analytics → `law-policy-governance` → Logs**:

```kql
// All exemptions created in the last 30 days
AzureActivity
| where TimeGenerated > ago(30d)
| where OperationNameValue == "Microsoft.Authorization/policyExemptions/write"
| where ActivityStatusValue == "Success"
| extend Body = parse_json(tostring(parse_json(Properties).requestbody))
| project TimeGenerated, Caller,
    ExemptionName = tostring(Body.properties.displayName),
    ExpiresOn     = tostring(Body.properties.expiresOn),
    Requester     = tostring(parse_json(tostring(Body.properties.metadata)).requester)
| order by TimeGenerated desc
```

```kql
// Active exemptions with days remaining
AzureActivity
| where OperationNameValue == "Microsoft.Authorization/policyExemptions/write"
| where ActivityStatusValue == "Success"
| extend Body      = parse_json(tostring(parse_json(Properties).requestbody))
| extend ExpiresOn = todatetime(tostring(Body.properties.expiresOn))
| where ExpiresOn > now()
| project
    ExemptionName  = tostring(Body.properties.displayName),
    DaysRemaining  = datetime_diff('day', ExpiresOn, now()),
    Requester      = tostring(parse_json(tostring(Body.properties.metadata)).requester),
    Team           = tostring(parse_json(tostring(Body.properties.metadata)).team)
| order by DaysRemaining asc
```

---

## Cleanup

```bash
# Delete active exemptions first, then destroy in reverse order
az rest --method DELETE \
  --uri "https://management.azure.com/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<sa>/providers/Microsoft.Authorization/policyExemptions/<name>?api-version=2022-07-01-preview"

# Destroy all infrastructure
cd environments
terraform destroy -auto-approve
```

---

## Contributing

PRs are welcome! Ideas for extension:

- Microsoft Teams Adaptive Card approval (alternative to email)
- Second approval tier for exemptions > 30 days
- ServiceNow / Jira auto-update on approval
- Self-service exemption portal (Azure Static Web Apps)

---

## Author

**Infantus Godfrey** · [GitHub @infantusgodfrey](https://github.com/infantusgodfrey)

If you found this useful, ⭐ star the repo and share the article — it helps more engineers find it.

---

## License

MIT — free to use, modify, and distribute with attribution.
