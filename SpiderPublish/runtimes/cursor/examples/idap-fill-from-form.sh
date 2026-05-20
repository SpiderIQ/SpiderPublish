#!/bin/bash
# SpiderPublish — build an agency-intake Form that fills the tenant CRM on submit.
#
# Mirrors recipes/idap-fill-from-form (shared/recipes/idap-fill-from-form/SKILL.md).
# Each field carries a crm_target wiring it to a norm_cli_<tenant>.<resource>.<column>
# row, plus IDAP-anchored field types (url / country / address / place / currency)
# so the value is structurally compatible with the column.
#
# Usage:
#   TOKEN="<PAT>" bash idap-fill-from-form.sh
#
# Optional env overrides:
#   API_BASE    default: https://spideriq.ai
#   FORM_NAME   default: "Agency intake — new client kickoff"
#
# Output: prints flow_id, status, and the public preview URL.

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
API_BASE="${API_BASE:-https://spideriq.ai}"
FORM_NAME="${FORM_NAME:-Agency intake — new client kickoff}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"

# ─── 1. Create the form — 9 fields with crm_target + IDAP types ──────────────
echo "1. Creating IDAP-wired form '$FORM_NAME'..."
CREATE_BODY=$(jq -n --arg name "$FORM_NAME" \
  '{
    name: $name,
    flow: {
      kind: "form",
      schema_version: "1.0.0",
      flow: [{
        id: "form", type: "form", label: "Form",
        fields: [
          { id: "contact_name",   type: "text",  label: "Your name",         required: true,
            crm_target: { resource_type: "contacts", column: "full_name" } },

          { id: "work_email",     type: "email", label: "Work email",        required: true,
            crm_target: { resource_type: "contacts", column: "email" } },

          { id: "company_website", type: "url",  label: "Company website",   required: true,
            url_variant: "website",
            crm_target: { resource_type: "businesses", column: "website" } },

          { id: "linkedin",       type: "url",   label: "Your LinkedIn",     required: false,
            url_variant: "linkedin_url",
            crm_target: { resource_type: "contacts", column: "linkedin_url" } },

          { id: "billing_country", type: "country", label: "Billing country", required: true,
            crm_target: { resource_type: "businesses", column: "country_code" } },

          { id: "billing_address", type: "address", label: "Registered office address",
            required: true,
            address_required_components: ["street_line_1", "city", "postal_code", "country"],
            crm_target: { resource_type: "company_registry", column: "address_line1" } },

          { id: "kickoff_when",   type: "datetime", label: "When can we kick off?", required: true },

          { id: "monthly_budget", type: "currency",
            label: "Monthly budget", required: true,
            currency_mode: "with_picker",
            default_currency: "USD",
            currencies: ["USD", "EUR", "GBP"] },

          { id: "office_location", type: "place", label: "Where is your main office?",
            required: false,
            place_types: ["establishment"],
            crm_target: { resource_type: "businesses", column: "google_place_id" } }
        ]
      }]
    }
  }')

CREATE=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CREATE_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows")
FLOW_ID=$(echo "$CREATE" | jq -r '.flow_id // .id // empty')
[ -n "$FLOW_ID" ] || { echo "form_create failed: $CREATE" >&2; exit 1; }
echo "   flow_id: $FLOW_ID"

# ─── 2. Publish — 2-phase, with the per-tenant column validation gate ────────
echo "2. Publishing — server validates every crm_target against the column's data_type..."
DRY_BODY=$(jq -n --arg title "$FORM_NAME" \
  '{ title: $title, length_minutes: 1, team_id: 0, dry_run: true }')
DRY=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DRY_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID/publish")

CONFIRM_TOKEN=$(echo "$DRY" | jq -r '.confirm_token // empty')
if [ -z "$CONFIRM_TOKEN" ]; then
  echo
  echo "Publish refused. Most common reason: a crm_target points at a column that"
  echo "doesn't exist on this tenant's norm_cli_* schema (e.g. company_registry."
  echo "address_line1 only exists when the company-registry pipeline is provisioned)."
  echo "Trim those fields or drop the crm_target and rerun."
  echo
  echo "Server response:"
  echo "$DRY" | jq .
  exit 1
fi

CONFIRM_BODY=$(jq -n --arg title "$FORM_NAME" --arg ct "$CONFIRM_TOKEN" \
  '{ title: $title, length_minutes: 1, team_id: 0, confirm_token: $ct }')
PUB=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CONFIRM_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID/publish")
STATUS=$(echo "$PUB" | jq -r '.status // empty')

echo
echo "Done."
echo "  flow_id:     $FLOW_ID"
echo "  status:      $STATUS"
echo "  Preview URL: $API_BASE/f/$FLOW_ID    # (legacy /book/$FLOW_ID still 301-redirects)"
echo
echo "On submit, each field with a crm_target dual-writes into"
echo "  norm_cli_<tenant>.<resource_type>.<column>"
echo "via the CRM sync cron (~60s lag from submit)."
