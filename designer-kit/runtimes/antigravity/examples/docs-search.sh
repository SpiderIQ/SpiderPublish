#!/bin/bash
# SpiderPublish — Full-text search your published docs (+ reader feedback)
#
# What this does:
#   Searches a tenant's PUBLISHED docs with Postgres full-text search and
#   returns highlighted snippets. Then (optionally) records a reader's
#   "Was this helpful?" vote against a doc.
#
#   GET  /api/v1/content/docs/search?q=    — full-text over published docs
#   POST /api/v1/content/docs/feedback     — "was this helpful?" vote
#
# IMPORTANT — call on the PLATFORM host with X-Content-Domain:
#   Docs endpoints resolve the tenant from the X-Content-Domain header, NOT
#   from the request host. Calling https://<your-docs-domain>/docs/search 404s
#   (the /docs/{path} catch-all wins) — call https://spideriq.ai/... and pass
#   your docs domain in the header, exactly like /docs/tree.
#
# Keyword docs search is FREE. (AI "ask-the-docs" is a separate metered feature.)
#
# Usage:
#   DOCS_DOMAIN="docs.acme.com" Q="quickstart" bash docs-search.sh
#   DOCS_DOMAIN="docs.acme.com" DOC_PATH="/getting-started" HELPFUL=true bash docs-search.sh

set -euo pipefail

API="https://spideriq.ai/api/v1"
DOCS_DOMAIN="${DOCS_DOMAIN:?Set DOCS_DOMAIN=your-docs-domain (e.g. docs.acme.com)}"
Q="${Q:-}"                       # search query (>= 2 chars)
DOC_PATH="${DOC_PATH:-}"         # optional: doc full_path to leave feedback on
HELPFUL="${HELPFUL:-true}"       # optional: true | false
COMMENT="${COMMENT:-}"           # optional: free-text comment

DOMAIN_HDR="X-Content-Domain: $DOCS_DOMAIN"

# --- 1. Full-text search (only when Q is set) --------------------------------
if [ -n "$Q" ]; then
  echo "=== GET /content/docs/search?q=$Q (host=$DOCS_DOMAIN) ==="
  # Returns [{ title, full_path, section_title, snippet }] — snippet has <mark> tags.
  curl -sS "$API/content/docs/search?q=$(printf %s "$Q" | sed 's/ /%20/g')" -H "$DOMAIN_HDR"
  echo
fi

# --- 2. Leave reader feedback (only when DOC_PATH is set) --------------------
if [ -n "$DOC_PATH" ]; then
  echo "=== POST /content/docs/feedback (doc_path=$DOC_PATH, helpful=$HELPFUL) ==="
  curl -sS -X POST "$API/content/docs/feedback" \
    -H "$DOMAIN_HDR" -H "Content-Type: application/json" \
    -d "{\"doc_path\":\"$DOC_PATH\",\"helpful\":$HELPFUL,\"comment\":\"$COMMENT\"}"
  echo
fi

if [ -z "$Q" ] && [ -z "$DOC_PATH" ]; then
  echo "Nothing to do — set Q=<query> to search, or DOC_PATH=<path> to leave feedback." >&2
  exit 1
fi
