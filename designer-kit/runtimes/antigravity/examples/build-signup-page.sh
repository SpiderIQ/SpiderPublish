#!/usr/bin/env bash
#
# Build a SELF-SERVE SIGNUP page with the designable Authentication brick.
#
# The same <spideriq-auth> brick that does login / forgot / reset also does
# SIGNUP via mode="signup" (auth_target=dashboard). A visitor on YOUR domain
# creates a brand-new free SpiderIQ account — in its OWN fresh workspace (not
# yours; your domain is just the entry point), on the free tier, no charge at
# signup. This script walks the canonical flow:
#
#   1. discover the auth components (category=authentication)
#   2. create a /signup page
#   3. insert spideriq/auth-login with mode=signup + auth_target=dashboard
#   4. publish + deploy
#   5. visual-check the published URL → assert shadow_hosts includes 'spideriq-auth'
#
# THE SIGNUP CONTRACT (read before you wire it):
#   * NO session is minted at signup. On submit the brick shows a neutral
#     "Check your email…" state and does NOT navigate or set a cookie. The
#     dashboard session exists only AFTER the visitor clicks the verification
#     link (→ /login?verified=1) and logs in. Don't expect a redirect.
#   * login-link="/login" gives the "Already have an account? Sign in" affordance.
#   * Duplicate email → same neutral response (no enumeration, no second account).
#
# STATUS: signup is functional end to end for auth_target=dashboard. Design the
# page freely and embed the brick where the form goes.
#
# Pairs with: examples/build-login-page.sh  •  recipes/build-a-login-page/
#             components/auth-login.json
#
# Auth: requires a PAT — run `npx @spideriq/cli@latest auth request -e <email>`
# first, then `spideriq use <project>` to bind this directory to a project.
#
# Usage:
#   ./build-signup-page.sh                # creates /signup (auth_target=dashboard)

set -euo pipefail

API_URL="${SPIDERIQ_API_URL:-https://spideriq.ai}"

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

# ─── 2. Create the /signup page ────────────────────────────────────────────
echo
echo "2. create page slug=signup"
PAGE_ID=$(curl -sS -X POST "${API_URL}/api/v1/dashboard/content/pages" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
  -d '{"slug":"signup","title":"Create your account","blocks":[]}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
if [ -z "$PAGE_ID" ]; then echo "page create failed"; exit 1; fi
echo "   → page_id: ${PAGE_ID}"

# ─── 3. Insert the brick in signup mode (auth_target=dashboard REQUIRED) ────
echo
echo "3. insert spideriq/auth-login (mode=signup, auth_target=dashboard)"
PROPS=$(python3 -c "
import json
print(json.dumps({
  'mode': 'signup',
  'auth_target': 'dashboard',
  'api_base': 'https://spideriq.ai',
  'login_link': '/login',         # 'Already have an account? Sign in'
  'methods': ['email_password'],
}))
")
# dry_run first (destructive ops are 2-phase: preview → confirm)
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
echo "5. visual-check the published /signup URL:"
cat <<'VERIFY'
   content_visual_check {
     page_url: "https://<your-site>/signup",
     expected_no_text: ["Page not found", "couldn't load"]
   }
   # PASS when dom.shadow_hosts includes "spideriq-auth".
   # NEVER assert on body_text_preview — the closed shadow root is opaque.
VERIFY

echo
echo "Done. Wire the matching /login page (examples/build-login-page.sh) and"
echo "add signup-link=\"/signup\" to that login brick so 'Create one' is a real link."
echo
echo "Remember: signup mints NO session — the visitor must verify their email,"
echo "then log in, before a dashboard session exists. The account lands in its"
echo "OWN fresh free-tier workspace (not yours)."
