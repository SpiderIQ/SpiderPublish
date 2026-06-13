---
name: members-gated-page
description: "Put a page behind a members login wall (Site Members — the site's OWN members, not the SpiderIQ dashboard). Every page has an access level: public (default) | logged_in (any member of this site) | group-restricted (named groups only). Set it with page_set_access (access + allowed_groups), ensure a login page on the SAME site uses auth_target=site_members (the member cookie is host-only ⇒ same-host sign-in), then publish + deploy so the Cloudflare edge enforces the gate, and visual-check (anonymous → redirected to /login; member → renders). Members / groups / invitations / SSO / Data Restrictions are managed in the dashboard Content → Users area. Use whenever the user asks for 'a members-only page', 'gate this page behind login', 'only logged-in users should see X', 'a client portal', or 'restrict this page to a group'."
---
# recipes/members-gated-page

Put a page behind a **members login wall** — the site's own members, not the SpiderIQ dashboard. This is SpiderPublish's "Site Members" (Softr-Users-class): a page can be `public`, `logged_in` (any member of this site), or `group-restricted` (members of named groups only).

Use this whenever the user asks for "a members-only page", "gate this page behind login", "only logged-in users should see X", "a client portal", or "restrict this page to a group".

## The two pieces

A members-gated site needs **two** things on the same site:

1. **A page with an access level** — set `access` to `logged_in` or `group-restricted` on the page you want to protect.
2. **A login page members can use** — an Authentication brick with `auth_target="site_members"` so a visitor has somewhere to sign in (see `recipes/build-a-login-page`).

The member session cookie is **host-only**: it is set on the site's own domain, so the login form must live on the **same site** as the gated pages. SpiderPublish wires the login brick to the page's own origin automatically when you leave `members_base` unset.

## Steps

```
# 1. Create (or pick) the page to protect
content_create_page(slug="portal", title="Client Portal")

# 2. Set its access level
#    public (default) | logged_in | group-restricted
page_set_access(
  page_id = "<portal page uuid>",
  access = "logged_in"
)
# For group-restricted, also pass the allowed group slugs:
# page_set_access(page_id=..., access="group-restricted", allowed_groups=["clients"])

# 3. Make sure a login page exists (auth_target = site_members)
#    See recipes/build-a-login-page — insert spideriq/auth-login with
#    auth_target="site_members" on a /login page of THIS site.

# 4. Publish + deploy so the edge picks up the gate
content_publish_page(id="<portal page uuid>")
content_deploy_production(confirm_token="<from dry_run>")

# 5. Verify the gate
content_visual_check(page_url="https://<site>/portal")
# Anonymous → redirected to /login (the gate works).
# A signed-in member → the page renders.
```

## The three access levels

| `access` | Who sees the page |
|---|---|
| `public` (default) | everyone — no gating, no overhead |
| `logged_in` | any signed-in member of this site |
| `group-restricted` | only members whose group is in the page's `allowed_groups` |

New pages are `public` by default, so adding members never changes a page you didn't explicitly gate.

## Managing members

Members, groups, invitations, SSO providers, and record-level Data Restrictions are managed from the dashboard **Content → Users** area. The per-member management API is dashboard/session-scoped (not the public PAT surface today), so an agent sets a page's `access` via `page_set_access` and hands member administration to the site owner in the dashboard. Full agent tooling for member/group/SSO management is on the roadmap.

## Anti-patterns

- **Putting the login form on a different host than the gated pages.** The member session cookie is host-only — a cross-origin login form silently fails to sign the visitor in. Keep the login page on the same site; leave `members_base` unset so the renderer wires it to the page's own origin.
- **Confusing `auth_target`.** For Site Members the login brick MUST use `auth_target="site_members"` — `auth_target="dashboard"` signs into the SpiderIQ dashboard, a different identity system that won't unlock your gated pages.
- **Forgetting to deploy.** The access level is enforced at the Cloudflare edge — it only takes effect after you publish the page and deploy the site.
- **Expecting one site's members to work on another.** Members are isolated per site by design; a member of site A cannot access site B.

Pairs with: `recipes/build-a-login-page` • `examples/members-gated-page.sh`
