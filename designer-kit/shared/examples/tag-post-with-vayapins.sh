#!/bin/bash
# SpiderPublish — tag a blog post with VayaPin locations → auto card strip (2026-06-04)
#
# A post can declare which VayaPin locations it "fits". The blog template then
# renders a "VayaPins in this article" card strip at the bottom automatically —
# each card = logo/photo + name + link to vayapin.com/CC:NAME. Pulled live from
# VayaPin at publish time, so it never goes stale.
#
# Pin ids look like BB:TAPAS (COUNTRY:SLUG, uppercase). Resolve valid ids first
# with GET /content/vayapin/cards — unknown / unlisted pins are silently skipped.
#
# Usage:
#   TOKEN="cli_xxx:key:secret" bash tag-post-with-vayapins.sh
#
# To do the same from the CLI instead:
#   spideriq content posts update <post-id> --vayapin-pins "BB:TAPAS,BB:CHAMPERS"

set -euo pipefail

TOKEN="${TOKEN:-${SPIDERIQ_PAT:-}}"
API="${SPIDERIQ_API_URL:-https://spideriq.ai}/api/v1"
[ -n "$TOKEN" ] || { echo "Set TOKEN=cli_id:key:secret"; exit 1; }

auth=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json")

# 1) Discover valid pin ids for what the article is about
echo "→ Resolving VayaPins for 'restaurants in Barbados'..."
curl -s "${auth[@]}" \
  "$API/content/vayapin/cards?country=bb&category=restaurant&limit=5" \
  | python3 -c "import json,sys; [print('  ', c['vayapin'], '—', c.get('title')) for c in json.load(sys.stdin).get('cards',[])]"

# 2) Create a post tagged with the pins it mentions (status=draft)
echo "→ Creating a post tagged with BB:TAPAS + BB:CHAMPERS..."
POST_ID=$(curl -s -X POST "${auth[@]}" "$API/dashboard/content/posts" -d '{
  "title": "The best places to eat in Barbados",
  "slug": "best-places-eat-barbados",
  "status": "draft",
  "excerpt": "A few of our favourites.",
  "vayapin_pins": ["BB:TAPAS", "BB:CHAMPERS"],
  "body": {"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Two spots worth the trip..."}]}]}
}' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "  post id: $POST_ID"

# 3) Publish it — the card strip now renders at the bottom of the article
echo "→ Publishing..."
curl -s -X POST "${auth[@]}" "$API/dashboard/content/posts/$POST_ID/publish" >/dev/null
echo "  done — open the post; the 'VayaPins in this article' strip is at the bottom."
