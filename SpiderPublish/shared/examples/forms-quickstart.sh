#!/bin/bash
# SpiderPublish — Stand up a SpiderFlow form from zero (v1.14.5+, P1 GA)
#
# What this does:
#   Creates a multi-step lead-capture form, adds fields, adds a conditional
#   logic rule using the canonical LogicRule shape, publishes it (Phase
#   11+12 dry_run → confirm_token), and emits an embed snippet you can
#   drop into any third-party page.
#
# Use this for:
#   - Bootstrapping a Typeform-class form in 60s for QA or demos
#   - Verifying your PAT + workspace binding before authoring a real form
#   - Smoke-testing the form_* MCP tool surface from a curl shell
#
# Preferred path — MCP/CLI:
#   spideriq form create --from-file form.json
#   spideriq form get <flow_id> --format yaml
#   spideriq form publish <flow_id> --dry-run
#   spideriq form publish <flow_id> --confirm <token>
#   spideriq form embed-snippet <flow_id> --mode popup --button-text "Get a Quote"
#
# This shell script is the curl fallback for runtimes without Node.
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" PID="cli_xxx" \
#   FORM_NAME="Free trial signup" \
#   bash forms-quickstart.sh
#
# Reads:    None (writes everything via API)
# Writes:   New booking_flow row (kind='form'), new submission row (test=true)
# Side-fx:  Form is published live at /book/<flow_id> on the tenant's primary domain
#
# Note on business_id:
#   `booking_flows.business_id` is NOT NULL FK (booking-side migration 123).
#   For `kind='form'` the backend resolves a per-tenant sentinel business
#   transparently — OMIT `business_id` from the create payload.

set -euo pipefail

: "${TOKEN:?Required: TOKEN=cli_xxx:sk_xxx:secret_xxx (your PAT)}"
: "${PID:?Required: PID=cli_xxx (project_id from .spideriq.json)}"
: "${API_URL:=https://spideriq.ai}"
: "${FORM_NAME:=Quickstart trial form}"

H_AUTH="Authorization: Bearer $TOKEN"
H_JSON="Content-Type: application/json"

echo "▶ Creating form (no business_id — sentinel resolved server-side)..."
CREATE_BODY=$(cat <<EOF
{
  "name": "$FORM_NAME",
  "kind": "form",
  "step_label": "Lead capture",
  "fields": [
    {"id": "q1", "type": "email",      "label": "Your work email",   "required": true},
    {"id": "q2", "type": "short_text", "label": "Company name",      "required": true},
    {"id": "q3", "type": "dropdown",   "label": "Team size",
     "options": [
       {"label": "1-10",  "value": "small"},
       {"label": "11-50", "value": "medium"},
       {"label": "51+",   "value": "large"}
     ]}
  ]
}
EOF
)

CREATE_RESP=$(curl -fsS -X POST "$API_URL/api/v1/booking/flows" \
  -H "$H_AUTH" -H "$H_JSON" -d "$CREATE_BODY")
FLOW_ID=$(echo "$CREATE_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['flow_id'])")
echo "  ✔ flow_id = $FLOW_ID"

echo "▶ Adding a conditional logic rule (canonical {op, left, right?} shape per P1.W5)..."
LOGIC_BODY=$(cat <<EOF
{
  "patch": {
    "logic": [{
      "id": "rule_enterprise",
      "condition": {
        "op": "equals",
        "left":  {"kind": "field",   "value": "q3"},
        "right": {"kind": "literal", "value": "large"}
      },
      "action": {"type": "jump_to", "field_id": "q3"}
    }]
  }
}
EOF
)
curl -fsS -X PATCH "$API_URL/api/v1/booking/flows/$FLOW_ID" \
  -H "$H_AUTH" -H "$H_JSON" -d "$LOGIC_BODY" >/dev/null
echo "  ✔ logic rule added"

echo "▶ Test-submitting against the form (?test=true)..."
SUBMIT_BODY='{"answers":{"q1":"test@example.com","q2":"Acme Co","q3":"medium"}}'
curl -fsS -X POST "$API_URL/api/v1/booking/$FLOW_ID/submit?test=true" \
  -H "$H_JSON" -H "Idempotency-Key: $(uuidgen 2>/dev/null || date +%s)" \
  -d "$SUBMIT_BODY" >/dev/null
echo "  ✔ test submission accepted"

echo "▶ Publishing the form (dry_run → confirm_token → confirm)..."
PUBLISH_DRY=$(curl -fsS -X POST "$API_URL/api/v1/booking/flows/$FLOW_ID/publish?dry_run=true" \
  -H "$H_AUTH" -H "$H_JSON" -d '{}')
CONFIRM_TOKEN=$(echo "$PUBLISH_DRY" | python3 -c "import json,sys; print(json.load(sys.stdin)['confirm_token'])")
echo "  ✔ confirm_token = $CONFIRM_TOKEN"

curl -fsS -X POST "$API_URL/api/v1/booking/flows/$FLOW_ID/publish?confirm_token=$CONFIRM_TOKEN" \
  -H "$H_AUTH" -H "$H_JSON" -d '{}' >/dev/null
echo "  ✔ form is live at $API_URL/book/$FLOW_ID"

echo "▶ Embed snippet (drop into any third-party page):"
cat <<EOF

  <!-- inline -->
  <div data-spiderflow-flow="$FLOW_ID" data-spiderflow-mode="inline"></div>
  <script async src="https://embed.spideriq.ai/v1/loader.js"></script>

  <!-- popup -->
  <button data-spiderflow-flow="$FLOW_ID" data-spiderflow-mode="popup"
          data-spiderflow-trigger-text="Get a Quote">Get a Quote</button>
  <script async src="https://embed.spideriq.ai/v1/loader.js"></script>

EOF
echo "✔ Done. flow_id=$FLOW_ID"
