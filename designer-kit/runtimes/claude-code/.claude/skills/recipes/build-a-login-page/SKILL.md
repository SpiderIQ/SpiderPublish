---
name: build-a-login-page
description: "Add a sign-in / forgot-password / reset-password page using the designable Authentication components (spideriq/auth-login, auth-forgot-password, auth-reset-password). Each renders a single <spideriq-auth> custom element with a CLOSED shadow DOM. The REQUIRED auth_target prop picks the identity system — 'dashboard' (sign into the SpiderIQ dashboard) or 'site_members' (sign into the site's own members). Discover via content_list_marketplace_components(category=authentication), insert with page_insert_section, verify via dom.shadow_hosts. Use whenever the user asks for 'a login page', 'a sign-in form', 'a forgot password page', or 'a reset password page'. Designable shell + contract — the sign-in backends ship in a follow-up."
---
# recipes/build-a-login-page

Add a sign-in page to a site using the designable **Authentication** components — `spideriq/auth-login`, `spideriq/auth-forgot-password`, `spideriq/auth-reset-password`. Each renders ONE `<spideriq-auth>` custom element with a **closed** shadow DOM (the password field is never readable from the host page).

Use this whenever the user asks for a "login page", "sign-in form", "forgot password page", or "reset password page".

## The hinge: `auth_target` (REQUIRED)

Every auth component **requires** an `auth_target` prop — it has no default and the two values lead to different identity worlds that never share a user store or session:

| `auth_target` | Signs into |
|---|---|
| `dashboard` | the SpiderIQ dashboard |
| `site_members` | the site's **own** members area |

Ask the user which one they want **before** inserting — it can't be swapped after sign-in.

## Quick ask: "add a login page to sign into the dashboard"

```
# 1. Discover the components
content_list_marketplace_components(category="authentication")
# → spideriq/auth-login, spideriq/auth-forgot-password, spideriq/auth-reset-password

# 2. Create the page
content_create_page(slug="login", title="Sign in")

# 3. Insert the login brick — auth_target is REQUIRED
page_insert_section(
  page_id = "<login page uuid>",
  component_slug = "spideriq/auth-login",
  props = {
    "auth_target": "dashboard",
    "methods": ["email_password", "google"],
    "signup_enabled": true,
    "forgot_link": "/forgot-password",
    "redirect_after": "/",
    "theme": { "primary_color": "#6d28d9", "button_radius": "8px" }
  },
  position = "end"
)

# 4. Publish + deploy
content_publish_page(id="<login page uuid>")
content_deploy_production(confirm_token="<from dry_run>")

# 5. Verify the closed-shadow host rendered
content_visual_check(page_url="https://<site>/login")
# PASS when dom.shadow_hosts includes "spideriq-auth".
```

Add `/forgot-password` (`spideriq/auth-forgot-password`) and `/reset-password` (`spideriq/auth-reset-password`) the same way; wire `login_link` / `forgot_link` between the pages as page refs.

## CLI equivalent

```
npx spideriq content marketplace:components --category authentication
npx spideriq content pages new --slug login --title "Sign in"
# insert + publish + deploy via the content commands
```

## Status — designable shell, backends rolling out

This first release ships the **designable shell + the integration contract** — not working auth. Until the sign-in backends ship, a placed form renders and themes correctly but degrades gracefully on submit (*"Sign-in isn't configured for this site yet"*). That is expected, not a bug.

## Anti-patterns

- **Omitting `auth_target`.** It is REQUIRED — the component cannot guess which identity system to use.
- **Asserting on `body_text_preview` to verify the form rendered.** `<spideriq-auth>` uses a **closed** shadow DOM, so the host page can't read inside it. Assert on `dom.shadow_hosts` including `spideriq-auth` instead.
- **Initiating OAuth on the site's own domain when `auth_target=dashboard`.** `google` / `github` always redirect to the central SpiderIQ origin for the OAuth dance.
- **Expecting end-to-end sign-in today.** It degrades gracefully until the backends ship.

Pairs with: `examples/build-login-page.sh` • `components/auth-login.json`
