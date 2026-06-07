#!/bin/bash
# SpiderPublish — Read your media catalog (list / search / fetch)
#
# What this does:
#   Reads the per-tenant media catalog — every image, video, and doc you've
#   hosted on SpiderIQ, across all storage tiers (R2 / SeaweedFS / PeerTube) —
#   over one normalized, read-only REST surface.
#
#   GET /api/v1/media/catalog/assets         — list (newest first, filters AND-combine)
#   GET /api/v1/media/catalog/assets/{id}    — fetch one asset by UUID
#   GET /api/v1/media/catalog/search         — substring on key/folder + tag overlap (ANY)
#
# Preferred path — MCP/CLI (no curl, agent-friendly):
#   spideriq media list --kind image --limit 20
#   spideriq media search "hero" --tags campaign
#   spideriq media get <asset_id>
#   ...or the @spideriq/mcp-media tools: catalog_list_assets / catalog_search_assets / catalog_get_asset
#
# This shell script is the curl fallback for runtimes without Node.
#
# Every GET accepts ?format=yaml|md for token-efficient agent responses
# (default is JSON). This example uses yaml.
#
# Usage:
#   TOKEN="cli_xxx:sk_xxx:secret_xxx" bash media-catalog-list.sh
#   TOKEN="..." Q="hero" KIND="image" bash media-catalog-list.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
AUTH="Authorization: Bearer ${TOKEN:?Set TOKEN=cli_id:api_key:api_secret}"
KIND="${KIND:-}"          # optional: image | video | doc
Q="${Q:-}"               # optional: search query (substring on key/folder)
LIMIT="${LIMIT:-20}"
FORMAT="${FORMAT:-yaml}"  # yaml | md | json

# --- 1. List the newest assets (optionally filtered by kind) -----------------
echo "=== GET /media/catalog/assets (kind=${KIND:-any}, limit=$LIMIT, format=$FORMAT) ==="
LIST_URL="$API/media/catalog/assets?limit=$LIMIT&format=$FORMAT"
[ -n "$KIND" ] && LIST_URL="$LIST_URL&kind=$KIND"
curl -sS "$LIST_URL" -H "$AUTH"
echo

# --- 2. Search the catalog (only when Q is set) ------------------------------
if [ -n "$Q" ]; then
  echo "=== GET /media/catalog/search?q=$Q ==="
  SEARCH_URL="$API/media/catalog/search?q=$Q&limit=$LIMIT&format=$FORMAT"
  [ -n "$KIND" ] && SEARCH_URL="$SEARCH_URL&kind=$KIND"
  curl -sS "$SEARCH_URL" -H "$AUTH"
  echo
fi

# --- 3. Fetch a single asset by id (only when ASSET_ID is set) ---------------
if [ -n "${ASSET_ID:-}" ]; then
  echo "=== GET /media/catalog/assets/$ASSET_ID ==="
  curl -sS "$API/media/catalog/assets/$ASSET_ID?format=$FORMAT" -H "$AUTH"
  echo
fi
