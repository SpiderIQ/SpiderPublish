#!/usr/bin/env bash
#
# Build a login page with the designable Authentication components.
#
# The "authentication" marketplace category ships three
# designable sign-in bricks — login / forgot-password / reset-password — each
# rendering ONE <spideriq-auth> custom element with a CLOSED shadow DOM. This
# script walks the canonical flow end-to-end:
#
#   1. discover the auth components (category=authentication)
#   2. create a /login page
#   3. insert spideriq/auth-login with the REQUIRED auth_target prop
#   4. publish + deploy
#   5. visual-check the published URL → assert shadow_hosts includes 'spideriq-auth'
#
# THE HINGE — auth_target (REQUIRED on every auth component):
#   dashboard     → sign into the SpiderIQ dashboard
#   site_members  → sign into this site's OWN members area
# The two identity worlds never share a user store; pick one before inserting.
#
# STATUS: sign-in is functional end to end. With auth_target=dashboard a placed
# brick signs the user into the SpiderIQ dashboard (one-time code -> host-only
# handoff -> first-party session); with site_members it signs into this site's
# own members. Design the page freely and embed the brick where the form goes.
#
# Pairs with: recipes/build-a-login-page/  •  components/auth-login.json
#
# Auth: requires a PAT — run `npx @spideriq/cli@latest auth request -e <email>`
# first, then `spideriq use <project>` to bind this directory to a project.
#
# Usage:
#   ./build-login-page.sh                 # auth_target=dashboard (default)
#   ./build-login-page.sh site_members    # sign into the site's own members

set -euo pipefail

API_URL="${SPIDERIQ_API_URL:-https://spideriq.ai}"
AUTH_TARGET="${1:-dashboard}"

if [ "$AUTH_TARGET" != "dashboard" ] && [ "$AUTH_TARGET" != "site_members" ]; then
  echo "auth_target must be 'dashboard' or 'site_members' (got '${AUTH_TARGET}')"
  exit 1
fi

# ─── 0. Read PAT from ~/.spideriq/credentials.json ─────────────────────────
TOKEN_FILE="${HOME}/.spideriq/credentials.json"
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Not authenticated. Run: npx @spideriq/cli@latest auth request -e <admin-email>"
  exit 1
fi
TOKEN=$(python3 -c "import json,sys; d=json.load(open('${TOKEN_FILE}')); ws=d.get('default') or next(iter(d.values())); print(ws.get('token',''))")
if [ -z "$TOKEN" ]; then
  echo "No token found in ${TOKEN_FILE}"
  exit 1
fi
echo "✓ token loaded (${TOKEN:0:14}…${TOKEN: -4})"

# ─── 1. Discover the auth components ───────────────────────────────────────
echo
echo "1. list marketplace components, category=authentication"
curl -sS "${API_URL}/api/v1/content/marketplace/components?category=authentication" \
  -H "Authorization: Bearer ${TOKEN}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
items = d if isinstance(d, list) else d.get('components', d.get('items', []))
for c in items:
    print(f'   ✓ {c[\"slug\"]:34s} {c.get(\"name\",\"\")}')
"
# CLI equivalent: npx spideriq content marketplace:components --category authentication

# ─── 2. Create the /login page ─────────────────────────────────────────────
echo
echo "2. create page slug=login"
PAGE_ID=$(curl -sS -X POST "${API_URL}/api/v1/dashboard/content/pages" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
  -d '{"slug":"login","title":"Sign in","blocks":[]}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
if [ -z "$PAGE_ID" ]; then echo "page create failed"; exit 1; fi
echo "   → page_id: ${PAGE_ID}"

# ─── 3. Insert spideriq/auth-login (auth_target REQUIRED) ──────────────────
echo
echo "3. insert spideriq/auth-login (auth_target=${AUTH_TARGET})"
PROPS=$(python3 -c "
import json
p = {'auth_target': '${AUTH_TARGET}', 'methods': ['email_password','google'],
     'signup_enabled': True, 'forgot_link': '/forgot-password', 'redirect_after': '/'}
if '${AUTH_TARGET}' == 'dashboard':
    p['api_base'] = 'https://spideriq.ai'
print(json.dumps(p))
")
# dry_run first (Phase 11+12 — destructive ops are 2-phase: preview → confirm)
CONFIRM_TOKEN=$(curl -sS -X POST "${API_URL}/api/v1/dashboard/content/pages/${PAGE_ID}/insert-section?dry_run=true" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
  -d "{\"component_slug\":\"spideriq/auth-login\",\"props\":${PROPS},\"position\":\"end\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('confirm_token',''))")
if [ -n "$CONFIRM_TOKEN" ]; then
  curl -sS -X POST "${API_URL}/api/v1/dashboard/content/pages/${PAGE_ID}/insert-section?confirm_token=${CONFIRM_TOKEN}" \
    -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
    -d "{\"component_slug\":\"spideriq/auth-login\",\"props\":${PROPS},\"position\":\"end\"}" >/dev/null
  echo "   ✓ inserted"
else
  echo "   (no confirm_token — your CLI/MCP may insert in one call; see recipes/build-a-login-page/)"
fi

# ─── 4. Publish + deploy ───────────────────────────────────────────────────
echo
echo "4. publish the page, then deploy the site"
echo "   npx spideriq content pages publish ${PAGE_ID}"
echo "   npx spideriq content deploy            # dry_run → confirm_token → deploy"

# ─── 5. Verify — assert the closed-shadow host rendered ────────────────────
echo
echo "5. visual-check the published /login URL:"
cat <<'VERIFY'
   content_visual_check {
     page_url: "https://<your-site>/login",
     expected_no_text: ["Page not found"]
   }
   # PASS when dom.shadow_hosts includes "spideriq-auth".
   # NEVER assert on body_text_preview — the closed shadow root is opaque.
VERIFY

echo
echo "Done. Add /forgot-password (spideriq/auth-forgot-password) and"
echo "/reset-password (spideriq/auth-reset-password) the same way, wiring"
echo "login_link / forgot_link between them as page refs."
