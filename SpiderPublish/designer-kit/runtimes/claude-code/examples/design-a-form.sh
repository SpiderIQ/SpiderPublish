#!/bin/bash
# SpiderPublish — design an existing Form: pick a preset + override 2-3 tokens
#                  and attach a per-question background image.
#
# Mirrors recipes/design-a-form (shared/recipes/design-a-form/SKILL.md).
#
# Usage:
#   TOKEN="<PAT>" FLOW_ID="<existing flow_id>" bash design-a-form.sh
#
# Optional env overrides:
#   API_BASE   default: https://spideriq.ai
#   PRESET     default: fullscreen-dark   (the 6 bundled slugs: card-light |
#              fullscreen-dark | conversational-left | form-on-image |
#              minimal-print | agency-bold)
#   PRIMARY    default: #c9a86b           (hex; lands on --primary)
#   HEADING    default: '"Playfair Display", serif'
#   FIRST_FIELD_ID
#              default: name              (the field that gets a background image)
#   FIRST_FIELD_MEDIA_URL
#              default: https://media.spideriq.ai/demo/venue-grand.jpg
#
# Output: prints the updated theme + the public preview URL.

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
FLOW_ID="${FLOW_ID:-}"
API_BASE="${API_BASE:-https://spideriq.ai}"
PRESET="${PRESET:-fullscreen-dark}"
PRIMARY="${PRIMARY:-#c9a86b}"
HEADING="${HEADING:-\"Playfair Display\", serif}"
FIRST_FIELD_ID="${FIRST_FIELD_ID:-name}"
FIRST_FIELD_MEDIA_URL="${FIRST_FIELD_MEDIA_URL:-https://media.spideriq.ai/demo/venue-grand.jpg}"

: "${TOKEN:?Set TOKEN or SPIDERIQ_PAT}"
: "${FLOW_ID:?Set FLOW_ID — see https://docs.spideriq.ai/forms/list}"

# ─── 1. Apply preset + token overrides ───────────────────────────────────────
echo "1. Applying preset='$PRESET' with --primary=$PRIMARY + --font-heading override..."
THEME_BODY=$(jq -n \
  --arg preset  "$PRESET" \
  --arg primary "$PRIMARY" \
  --arg heading "$HEADING" \
  '{
    patch: {
      flow: {
        theme: {
          preset: $preset,
          tokens: {
            "--primary":          $primary,
            "--font-heading":     $heading,
            "--layout-padding-y": "4rem"
          }
        }
      }
    }
  }')
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$THEME_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID" \
  | jq '{flow_id, version, theme: .flow.theme}'

# ─── 2. Attach a background image to a single question ───────────────────────
# Patches the field's `media` block in-place. Mobile collapse + opacity handling
# are handled by the renderer.
echo
echo "2. Attaching background image to field '$FIRST_FIELD_ID'..."
GET=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID")
FIELDS=$(echo "$GET" | jq -c '.flow.flow[0].fields // []')

NEW_FIELDS=$(echo "$FIELDS" | jq \
  --arg id "$FIRST_FIELD_ID" \
  --arg url "$FIRST_FIELD_MEDIA_URL" \
  'map(if .id == $id
        then . + { media: { url: $url, type: "image", position: "background", opacity: 0.45 } }
        else .
        end)')

MEDIA_BODY=$(jq -n --argjson fields "$NEW_FIELDS" '{ patch: { flow: { flow: [{ id: "form", type: "form", fields: $fields }] } } }')
curl -s -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$MEDIA_BODY" \
  "$API_BASE/api/v1/dashboard/booking/flows/$FLOW_ID" \
  | jq '{flow_id, version}'

# ─── 3. Print the preview URL ────────────────────────────────────────────────
echo
echo "Done."
echo "  Preview URL: $API_BASE/book/$FLOW_ID"
echo "  Reload to see the new theme + first-question background."
