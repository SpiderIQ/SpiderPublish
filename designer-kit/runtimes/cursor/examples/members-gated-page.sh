#!/usr/bin/env bash
#
# Put a page behind a members login wall — Site Members.
#
# SpiderPublish "Site Members" lets a site gate its OWN pages behind a login
# wall for its OWN members (the Softr-Users model). Every page has an access
# level:
#
#   public            (default) → everyone; no gating
#   logged_in                   → any signed-in member of THIS site
#   group-restricted            → only members whose group is allowed on the page
#
# This script walks the canonical flow:
#
#   1. create the page to protect
#   2. set its access level (logged_in or group-restricted)
#   3. publish + deploy so the Cloudflare edge picks up the gate
#   4. visual-check: anonymous → redirected to /login; member → renders
#
# A members-gated site also needs a login page on the SAME site built with
# auth_target=site_members — see recipes/build-a-login-page and
# examples/build-login-page.sh site_members. The member session cookie is
# host-only, so the login form must be same-host as the gated pages.
#
# Members / groups / invitations / SSO / Data Restrictions are managed in the
# dashboard Content → Users area (per-member management is session-scoped
# today). This recipe covers setting a page's access level.
#
# Pairs with: recipes/members-gated-page/  •  recipes/build-a-login-page/
#
# Auth: requires a PAT — run `npx @spideriq/cli@latest auth request -e <email>`
# first, then `spideriq use <project>` to bind this directory to a project.
#
# Usage:
#   ./members-gated-page.sh                      # access=logged_in (default)
#   ./members-gated-page.sh group-restricted clients   # group-gate to 'clients'

set -euo pipefail

API_URL="${SPIDERIQ_API_URL:-https://spideriq.ai}"
ACCESS="${1:-logged_in}"
GROUP="${2:-}"
PAGE_SLUG="${PAGE_SLUG:-portal}"

if [ "$ACCESS" != "public" ] && [ "$ACCESS" != "logged_in" ] && [ "$ACCESS" != "group-restricted" ]; then
  echo "access must be 'public', 'logged_in', or 'group-restricted' (got '${ACCESS}')"
  exit 1
fi

# ─── 0. Read PAT from ~/.spideriq/credentials.json ─────────────────────────
TOKEN_FILE="${HOME}/.spideriq/credentials.json"
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Not authenticated. Run: npx @spideriq/cli@latest auth request -e <admin-email>"
  exit 1
fi
TOKEN=$(python3 -c "import json,sys; d=json.load(open('${TOKEN_FILE}')); ws=d.get('default') or next(iter(d.values())); print(ws.get('token',''))")
if [ -z "$TOKEN" ]; then echo "No token found in ${TOKEN_FILE}"; exit 1; fi
echo "✓ token loaded (${TOKEN:0:14}…${TOKEN: -4})"

# ─── 1. Create the page to protect ─────────────────────────────────────────
echo
echo "1. create page slug=${PAGE_SLUG}"
PAGE_ID=$(curl -sS -X POST "${API_URL}/api/v1/dashboard/content/pages" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
  -d "{\"slug\":\"${PAGE_SLUG}\",\"title\":\"Client Portal\",\"blocks\":[]}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
if [ -z "$PAGE_ID" ]; then echo "page create failed"; exit 1; fi
echo "   → page_id: ${PAGE_ID}"

# ─── 2. Set its access level ───────────────────────────────────────────────
echo
echo "2. set access=${ACCESS}${GROUP:+ (allowed_groups=[${GROUP}])}"
BODY=$(python3 -c "
import json
b = {'access': '${ACCESS}'}
if '${ACCESS}' == 'group-restricted':
    b['allowed_groups'] = ['${GROUP}'] if '${GROUP}' else []
print(json.dumps(b))
")
curl -sS -X PUT "${API_URL}/api/v1/dashboard/pages/${PAGE_ID}/access" \
  -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" \
  -d "${BODY}" >/dev/null && echo "   ✓ access set" \
  || echo "   (if this 401/403s, set the page's Visibility in the dashboard page editor instead)"

# ─── 3. Publish + deploy ───────────────────────────────────────────────────
echo
echo "3. publish the page, then deploy the site (the edge enforces access only after deploy)"
echo "   npx spideriq content pages publish ${PAGE_ID}"
echo "   npx spideriq content deploy            # dry_run → confirm_token → deploy"

# ─── 4. Verify the gate ────────────────────────────────────────────────────
echo
echo "4. visual-check the gated URL:"
cat <<VERIFY
   content_visual_check {
     page_url: "https://<your-site>/${PAGE_SLUG}"
   }
   # Anonymous  → redirected to /login (the gate works).
   # A member   → the page renders.
VERIFY

echo
echo "Done. Make sure a /login page exists on THIS site with"
echo "auth_target=site_members (see examples/build-login-page.sh site_members),"
echo "then invite members from the dashboard Content → Users area."
