#!/usr/bin/env bash
# content-export-and-audit.sh — export a page with its audit, parse the findings,
# decide what to fix.
#
# Three call paths shown below — pick whichever your shell supports:
#
#   1) CLI (preferred when @spideriq/cli is installed):
#        spideriq content export <page_id> [--format json|md|archive] [--output <path>]
#
#   2) MCP (preferred from inside an AI agent session):
#        content_export_page({page_id: "...", format: "json"})
#
#   3) Raw HTTP (fallback for shells without Node):
#        curl -H "Authorization: Bearer $SPIDERIQ_PAT" \
#          "$SPIDERIQ_API_URL/api/v1/dashboard/projects/$SPIDERIQ_PROJECT_ID/content/pages/<id>/export?format=json"
#
# All three paths return the same envelope. format=json is the default.

set -euo pipefail

PAGE_ID="${1:-}"
FORMAT="${2:-json}"

if [[ -z "$PAGE_ID" ]]; then
  echo "usage: $0 <page_id> [json|md|archive]" >&2
  exit 1
fi

# ───────────────────────────────────────────────────────────────────────────
# Path 1: CLI (preferred)
# ───────────────────────────────────────────────────────────────────────────
if command -v spideriq >/dev/null 2>&1; then
  case "$FORMAT" in
    json)
      echo "==> exporting $PAGE_ID as json (CLI)..."
      RAW=$(spideriq content export "$PAGE_ID" --format json)
      echo "$RAW" | jq '.audit.summary'
      echo
      echo "==> top errors:"
      echo "$RAW" | jq -r '.audit.site_level[] + .audit.page_level[] + .audit.block_level[] + .audit.component_level[] | select(.severity=="error") | "[" + .severity + "] " + .rule_id + " — " + .message'
      echo
      echo "==> top warnings:"
      echo "$RAW" | jq -r '.audit.site_level[] + .audit.page_level[] + .audit.block_level[] + .audit.component_level[] | select(.severity=="warn") | "[" + .severity + "] " + .rule_id + " — " + .message' | head -10
      ;;
    md)
      echo "==> exporting $PAGE_ID as Markdown (CLI)..."
      spideriq content export "$PAGE_ID" --format md --output "/tmp/${PAGE_ID}.export.md"
      echo "wrote /tmp/${PAGE_ID}.export.md"
      ;;
    archive)
      echo "==> exporting $PAGE_ID as ZIP (CLI)..."
      spideriq content export "$PAGE_ID" --format archive --output "/tmp/${PAGE_ID}.export.zip"
      echo "wrote /tmp/${PAGE_ID}.export.zip"
      echo
      echo "==> unzipping into /tmp/${PAGE_ID}.export/ (VSCode-extension-compatible layout)..."
      mkdir -p "/tmp/${PAGE_ID}.export"
      unzip -o "/tmp/${PAGE_ID}.export.zip" -d "/tmp/${PAGE_ID}.export/" >/dev/null
      ls -la "/tmp/${PAGE_ID}.export/"
      cat "/tmp/${PAGE_ID}.export/manifest.json"
      ;;
    *)
      echo "unknown format: $FORMAT" >&2
      exit 1
      ;;
  esac
  exit 0
fi

# ───────────────────────────────────────────────────────────────────────────
# Path 3: raw HTTP fallback
# ───────────────────────────────────────────────────────────────────────────
: "${SPIDERIQ_PAT:?set SPIDERIQ_PAT to your client_id:api_key:api_secret triple}"
: "${SPIDERIQ_API_URL:=https://spideriq.ai}"
: "${SPIDERIQ_PROJECT_ID:?set SPIDERIQ_PROJECT_ID to your client_id (e.g. cli_abc...)}"

URL="$SPIDERIQ_API_URL/api/v1/dashboard/projects/$SPIDERIQ_PROJECT_ID/content/pages/$PAGE_ID/export?format=$FORMAT"

case "$FORMAT" in
  json)
    echo "==> exporting $PAGE_ID as json (HTTP)..."
    curl -sS -H "Authorization: Bearer $SPIDERIQ_PAT" "$URL" | tee "/tmp/${PAGE_ID}.export.json" | jq '.audit.summary'
    ;;
  md)
    echo "==> exporting $PAGE_ID as Markdown (HTTP)..."
    curl -sS -H "Authorization: Bearer $SPIDERIQ_PAT" "$URL" -o "/tmp/${PAGE_ID}.export.md"
    echo "wrote /tmp/${PAGE_ID}.export.md"
    ;;
  archive)
    echo "==> exporting $PAGE_ID as ZIP (HTTP)..."
    curl -sS -H "Authorization: Bearer $SPIDERIQ_PAT" "$URL" -o "/tmp/${PAGE_ID}.export.zip"
    mkdir -p "/tmp/${PAGE_ID}.export"
    unzip -o "/tmp/${PAGE_ID}.export.zip" -d "/tmp/${PAGE_ID}.export/" >/dev/null
    ls -la "/tmp/${PAGE_ID}.export/"
    ;;
esac
