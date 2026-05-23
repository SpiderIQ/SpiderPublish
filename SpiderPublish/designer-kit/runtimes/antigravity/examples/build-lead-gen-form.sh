#!/bin/bash
# SpiderPublish — build a multi-step lead-gen Form end-to-end via the public REST API.
#
# Mirrors the build-lead-gen-form recipe (shared/recipes/build-lead-gen-form/SKILL.md).
# Hits the same endpoints the form_* MCP tools wrap, so you can run this in CI,
# inside a degraded MCP session, or anywhere bash + curl + jq are available.
#
# Usage:
#   TOKEN="<your PAT>" bash build-lead-gen-form.sh
#
# Optional env overrides:
#   API_BASE      default: https://spideriq.ai
#   FORM_NAME     default: "Free trial signup"
#   PRESET        default: card-light  (one of the 6 bundled preset slugs)
#   PRIMARY       default: #1f6feb     (hex for the --primary token)
#
# Output: prints the new flow_id, the public preview URL, and a paste-ready
# popup-mode embed snippet for any third-party page.

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
API_BASE="${API_BASE:-https://spideriq.ai}"
FORM_NAME="${FORM_NAME:-Free trial signup}"
PRESET="${PRESET:-card-light}"
PRIMARY="${PRIMARY:-#1f6feb}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT — see https://docs.spideriq.ai/quickstart}"

# ─── 1. Create the form with 3 initial fields + a theme ──────────────────────
echo "1. Creating form '$FORM_NAME'..."
CREATE_BODY=$(jq -n \
  --arg name    "$FORM_NAME" \
  --arg preset  "$PRESET" \
  --arg primary "$PRIMARY" \
  '{
    name: $name,
    flow: {
      kind: "form",
      schema_version: "1.0.0",
      theme: { preset: $preset, tokens: { "--primary": $primary, "--button-radius": "999px" } },
      flow: [
        {
          id: "form", type: "form", label: "Form",
          fields: [
            { id: "work_email",   type: "email", label: "Your work email", required: true,
              placeholder: "you@company.com" },
            { id: "company_name", type: "text",  label: "Company name",   required: true },
            { id: "team_size",    type: "select", label: "Team size",     required: true,
              options: [
                { label: "Just me",  value: "solo"   },
                { label: "2 – 10",   value: "small"  },
                { label: "11 – 50",  value: "medium" },
                { label: "51+",      value: "large"  }
              ] }
          ]
        }
      ],
      thankyou_screens: [{ id: "ok", title: "Thanks — we will be in touch within 1 business day." }]
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

# ─── 2. Add hidden UTM-capture fields ─────────────────────────────────────────
echo "2. Adding hidden utm_source + utm_campaign captures..."
PATCH_HIDDEN=$(jq -n '{
  patch: {
    flow: {
      hidden_fields: [
        { key: "utm_source",   label: "UTM source"   },
        { key: "utm_campaign", label: "UTM campaign" }
      ]
    }
  }
}')
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PATCH_HIDDEN" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID" \
  > /dev/null

# ─── 3. Publish — 2-phase confirm ─────────────────────────────────────────────
echo "3. Publishing (dry_run → confirm)..."
DRY_BODY=$(jq -n --arg title "$FORM_NAME" \
  '{ title: $title, length_minutes: 1, team_id: 0, dry_run: true }')
DRY=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DRY_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID/publish")
CONFIRM_TOKEN=$(echo "$DRY" | jq -r '.confirm_token // empty')
[ -n "$CONFIRM_TOKEN" ] || { echo "publish dry_run failed: $DRY" >&2; exit 1; }

CONFIRM_BODY=$(jq -n --arg title "$FORM_NAME" --arg ct "$CONFIRM_TOKEN" \
  '{ title: $title, length_minutes: 1, team_id: 0, confirm_token: $ct }')
PUB=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CONFIRM_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID/publish")
STATUS=$(echo "$PUB" | jq -r '.status // empty')
echo "   status: $STATUS"

# ─── 4. Print the preview URL + paste-ready popup embed snippet ───────────────
echo
echo "Done."
echo "  Preview URL:  $API_BASE/book/$FLOW_ID"
echo
echo "  Paste-ready embed snippet (popup mode):"
echo "  ─────────────────────────────────────────"
cat <<EOF
<button data-spiderflow-flow="$FLOW_ID"
        data-spiderflow-mode="popup"
        data-spiderflow-trigger-text="Start Free Trial">Start Free Trial</button>
<script src="https://embed.spideriq.ai/v1/loader.js" async></script>
EOF
