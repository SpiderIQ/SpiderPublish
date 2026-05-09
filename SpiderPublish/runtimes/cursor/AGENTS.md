# SpiderPublish — Cursor AGENTS.md

> **Built from canonical sources in [shared/](../../shared/).** Edit shared content there, run `npm run build` to regenerate.

Cursor reads this file plus per-skill rules under `.cursor/rules/*.mdc`. Each rule is loaded on demand based on its description match.

# SpiderPublish — AGENTS.md

> Full version: [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents)
> **VSCode / Cursor / Antigravity extension (v0.1.0+):** [docs.spideriq.ai/extension](https://docs.spideriq.ai/extension) — install the SpiderPublish extension to operate this CMS from your IDE: native diffs, snapshot-bound preview→confirm push, JSONPath → file:line diagnostics, pre-push link audit with "Accept redirect" Quick Fix. The extension wraps the same `@spideriq/mcp-publish` surface this AGENTS.md describes — anything you can do via raw MCP, you can do via the extension UI.
> **Antigravity Knowledge Items:** the kit ships 11 pre-built KIs in [`knowledge/antigravity/`](./knowledge/antigravity/) covering capability discovery, page creation, marketplace search, deploy, personalized landing, booking, scroll-sequence, GEO readability, MCP package picking, CLI reference, and IDE extension setup. Install with `bash examples/install-antigravity-kis.sh` — copies them to `~/.gemini/antigravity/knowledge/`. Antigravity auto-loads relevant KIs based on user intent; no `/slash` invocation needed.
> **Session Binding (Phase 11+12):** [docs.spideriq.ai/site-builder/sessions](https://docs.spideriq.ai/site-builder/sessions)
> **Deploy Safely (preview→confirm):** [docs.spideriq.ai/site-builder/deploy-safely](https://docs.spideriq.ai/site-builder/deploy-safely)
> Component Builder: [docs.spideriq.ai/site-builder/component-builder](https://docs.spideriq.ai/site-builder/component-builder)
> Tiers Reference: [docs.spideriq.ai/site-builder/component-tiers](https://docs.spideriq.ai/site-builder/component-tiers)
> Agent Reference: [docs.spideriq.ai/site-builder/component-agents-reference](https://docs.spideriq.ai/site-builder/component-agents-reference)

**Current package versions (1.7.0, 2026-05-06):** `@spideriq/cli@1.7.0`, `@spideriq/mcp-publish@1.7.0`, `@spideriq/core@1.6.0`. **New in 1.7.0:** `marketplace_suggest_agent_meta` — wraps the SpiderGate-powered inference engine so external LLM agents can suggest mood / palette / brand_fit_tags / scene_type / agent_meta for marketplace assets they upload (two-step: suggest → review → apply via the existing `set_*_agent_meta` tools). The atomic publish slice now exposes **7 Marketplace V2 tools** total (search, list_data_sources, set_component_kind, set_component_agent_meta, set_bg_video_agent_meta, set_site_template_agent_meta, marketplace_suggest_agent_meta) — see the "Marketplace V2" section below. The kitchen-sink `@spideriq/mcp@1.7.0` totals 126 tools and bundles SpiderBook booking + mail / leads / gate / admin slices. The starter kit's `.mcp.json` defaults to `@spideriq/mcp-publish` — under the ~128-tool injection limit enforced by some IDE/LLM stacks, and less context burn per message.

## Quick Reference

### Setup
1. Copy `.mcp.json` to your project root
2. Copy `CLAUDE.md` to your project root
3. Restart your IDE
4. Authenticate: `npx @spideriq/cli auth request --email admin@company.com`
5. **Bind this directory to a project** (mandatory): `npx @spideriq/cli use <project>` — writes `./spideriq.json`

From step 5 on, every dashboard call auto-rewrites to `/api/v1/dashboard/projects/{project_id}/...` and destructive tools default to `dry_run=true` (preview → confirm). Skipping step 5 falls back to legacy URLs that stop working 2026-05-14.

### Build a Site (follow ALL steps)
```
template_get_help                     → 0. Read the full content reference (tasks index, chrome_override, theme_palette, session_binding, deploy_workflow)
content_update_settings               → 1. REQUIRED: Set site_name + optional theme palette (see Theme Palette below)
   └─ default dry_run=true            →    First call returns preview + confirm_token. Call again with confirm_token to apply.
content_update_navigation             → 2. Set up header menu items (not gated)
content_create_page                   → 3. Create pages with blocks (slug "home" for homepage; template picks layout — see Page Templates; not gated)
content_publish_page                  → 4. REQUIRED: Publish at least 1 page
   └─ default dry_run=true            →    Same two-step flow
template_apply_theme                  → 5. REQUIRED: Apply "default" theme
   └─ default dry_run=true            →    Same two-step flow
content_deploy_readiness              → 6. Check if site is ready to deploy (not gated; read-only)
content_deploy_site_preview           → 7. Returns preview_url + confirm_token. Open preview_url in a browser.
content_deploy_site_production        → 8. Pass confirm_token from step 7. Deploys to Cloudflare edge (2-5s).
```

### Customize Header/Footer (NEW in v0.8.2)

Three tools for per-client theme-file overrides. THE supported path for site-chrome customization — do NOT build JS Shadow-DOM-escape hacks.

```
content_get_section_source            → Read current Liquid source for header | footer | layout | head | hero
content_override_section              → Upload custom Liquid that wins over the default theme
content_apply_layout_preset           → Apply a canned layout/theme.liquid: default | blank | landing
```

Typical workflow to "make the footer dark":
```
1. content_get_section_source({section: "footer"}) → returns { path, source, is_override }
2. modify the returned Liquid in your own context
3. content_override_section({section: "footer", liquid: modified})
4. content_deploy_site_preview() → content_deploy_site_production(confirm_token)
```

Used in production by danmagi.com, sms-chemicals.com, mail.spideriq.ai.

### Deploy Requirements

Deploy **rejects** if any blocking item is missing. Always call `content_deploy_readiness` first.

| Requirement | MCP Tool |
|-------------|----------|
| Site settings with `site_name` | `content_update_settings` |
| At least 1 verified domain | `content_add_domain` |
| At least 1 template (theme applied) | `template_apply_theme` |
| At least 1 published page | `content_publish_page` |

### Error Responses (Phase 11+12)

| Status | Cause | Fix |
|---|---|---|
| `403 TokenInvalid` | `confirm_token` doesn't exist | Issue a fresh one via `dry_run=true` |
| `403 TokenClientMismatch` | Token was for a different project | Wrong directory — check `spideriq.json` |
| `403 TokenActionMismatch` | Token was for a different action | Don't reuse tokens across operations |
| `409 TokenConsumed` | Single-use token already used | Issue a fresh one |
| `410 TokenExpired` | Past expires_at (7 days) | Issue a fresh one |
| `423 page_locked` | Page is locked by another actor (P4) | Read `detail.unlock_endpoint` + `locked_reason` — back off OR call `content_unlock_page` if you're the lock-holder |
| `403 force_required` | `?force=true` from a non-super_admin / non-brand_admin role | Either elevate, or wait for the lock-holder to unlock |

### Page Locking + Version Restore (P4, 2026-05-09)

Pages can be **locked** against further edits during client review or scheduled launch. Mutations on a locked page (`content_update_page`, `content_publish_page`, `content_unpublish_page`, `content_delete_page`, `content_insert_section`, `content_restore_page_version`) return **HTTP 423 Locked** with this body:

```json
{
  "detail": {
    "error": "page_locked",
    "message": "Page is locked by api:cli_xxx.",
    "locked_by_actor_id": "api:cli_xxx",
    "locked_at": "2026-05-09T21:11:00Z",
    "locked_reason": "client review week of 2026-05-12",
    "unlock_endpoint": "/api/v1/dashboard/projects/cli_xxx/content/pages/<id>/unlock"
  }
}
```

**Recovery path:** parse `locked_by_actor_id`. If it matches your `actor_id`, call `content_unlock_page({page_id})`. Otherwise read `locked_reason` — if it names a deadline, back off. Do NOT loop on the 423 retry without backoff; the lock provenance won't change until someone explicitly unlocks. Versions endpoints (`content_list_page_versions`, `content_get_page_version`) are read-only and work on locked pages.

**5 new MCP tools** in `@spideriq/mcp-publish@1.11.0+` and kitchen-sink `@spideriq/mcp@1.11.0+` (94 atomic tools total):

| Tool | What it does |
|---|---|
| `content_lock_page({page_id, reason?})` | Lock the page. Idempotent — re-locking refreshes `locked_at` and `reason`. |
| `content_unlock_page({page_id, force?})` | Unlock. Default — only the lock-holder. `force=true` requires super_admin or brand_admin (server-enforced). |
| `content_list_page_versions({page_id})` | Snapshot log (newest first) — `version_number`, `title`, `block_count`, `blocks_size`, `change_summary`, `created_at`. |
| `content_get_page_version({page_id, version_number})` | Single snapshot in full (with `blocks`) — diff against current before restore. |
| `content_restore_page_version({page_id, version_number, dry_run?, confirm_token?, force?})` | Phase 11+12 dry_run/confirm_token gated. Appends new version row recording the restore. |

Recipe walkthrough: [`shared/recipes/lock-during-review/SKILL.md`](../recipes/lock-during-review/SKILL.md).

### PAT Auth Errors (2026-04-24)

Distinguishable from the confirm-token errors above. Body is `{"detail": {"error": "<code>", "message": "...", "expires_at"?: "..."}}`.

| Status | `error` code | What it means |
|---|---|---|
| `401` | `token_expired` | Your PAT passed `expires_at`. Body includes `expires_at` + a link to regenerate. Run `spideriq auth request --email <admin>` or visit `https://app.spideriq.ai/settings/tokens`. |
| `401` | `token_invalid` | PAT is unknown/malformed. Check `~/.spideriq/credentials.json` or re-auth. |
| `401` | (no `error` field) | Legacy path — still supported but agents should treat as `token_invalid`. |

### `whoami` — check your binding (2026-04-24)

Before a destructive deploy, confirm which project your PAT is bound to:

```bash
curl -H "Authorization: Bearer $SPIDERIQ_PAT" https://spideriq.ai/api/v1/auth/whoami
# → {authenticated, auth_type, client_id, project_name, email, role, scopes, token_expires_at, token_id, session_binding}
# Or via CLI:
npx @spideriq/cli auth whoami
```

Returns the resolved project_name (company_name on the client record) — no more trial-and-error API calls to figure out which workspace a token belongs to.

### Common Mistakes

- **Forget `spideriq use`** → every call carries `Deprecation: true` header; will 410 after 2026-05-14
- **Call destructive tool without `confirm_token`** → you get a preview envelope instead of a mutation (by design)
- **Set `primary_color: "#000000"` expecting dark background** → primary_color is the ACCENT only; use `surface_color` + `body_text_color` + `heading_color` for the page palette (see Theme Palette)
- **Create component with slug "footer" to override the default** → Components ≠ theme sections. Use `content_override_section`
- **Build `document.querySelector('body > footer').style...` from component JS** → breaks on cache flush, FOUC. Use `content_override_section` instead
- **Reuse a `confirm_token`** → 409 on the second call (single-use)
- **Component slug reuse** → 400 error. Use update or increment version.
- **Deploying before publishing pages** → 400 "Missing: Published Pages"
- **Skipping settings** → 400 "Missing: Site Settings"
- **Skipping theme** → 400 "Missing: Theme / Templates"

### Duplicate page / post / doc / block (2026-04-24)

Cheap primitive that unblocks every "starter content" workflow — fork an existing page as a draft, deep-copy a block in place, re-use a blog post template. The duplicate gets `status='draft'`, fresh UUIDs on every block, and an auto-generated `{slug}-copy[-N]` slug (lowest unused suffix) unless you pass `new_slug`.

```bash
# MCP
content_duplicate_page(page_id="...", new_slug="...")     # optional new_slug
content_duplicate_block(page_id="...", block_id="...", position="after"|"before"|N)
content_duplicate_post(post_id="...", new_slug="...")
content_duplicate_doc(doc_id="...", new_slug="...")

# CLI
spideriq content pages:duplicate <page_id> [--slug <new>]
spideriq content blocks:duplicate <page_id> <block_id> [--position before|after|N]
spideriq content posts duplicate <post_id> [--slug <new>]
spideriq content docs:duplicate <doc_id> [--slug <new>]

# REST
POST /dashboard/projects/{pid}/content/pages/{page_id}/duplicate
POST /dashboard/projects/{pid}/content/pages/{page_id}/blocks/{block_id}/duplicate
POST /dashboard/projects/{pid}/content/posts/{post_id}/duplicate
POST /dashboard/projects/{pid}/content/docs/{doc_id}/duplicate
```

**Not gated by `dry_run`/`confirm_token`** — these are net-additive (new draft row), not destructive overwrites. 409 on slug collision when `new_slug` is provided; 404 if the source isn't owned by the caller's tenant. Title gets " (Copy)" appended so the dashboard shows it distinctly.

Runnable example: [examples/duplicate-page.sh](./examples/duplicate-page.sh).

### Block Types
`hero`, `features_grid`, `cta_section`, `testimonials`, `pricing_table`, `faq`, `stats_bar`, `rich_text`, `image`, `video_embed`, `code_example`, `logo_cloud`, `comparison_table`, `spacer`, `component`

### Block Payload Schema (strict since 2026-04-24)

Every block in `content_pages.blocks[]` has this canonical shape:

```json
{
  "id": "required unique string (UUID recommended)",
  "type": "one of the BlockType values above",
  "data": { /* type-specific; see below */ },
  "component_slug": "REQUIRED when type='component' (top-level, NOT data.slug)",
  "component_version": "optional pinned version; omit for latest published",
  "props": { /* optional dict passed to the component template */ }
}
```

**Type-specific `data` requirements:**

- `type: "component"` → MUST set `component_slug` at the block's top level.
  Reference JSON: [components/block-component.json](components/block-component.json).
- `type: "rich_text"` → MUST set `data.html` (raw HTML string) OR `data.content` (Tiptap JSON).
  Reference JSON: [components/block-rich-text.json](components/block-rich-text.json).
- Native-typed blocks (`hero`, `features_grid`, etc.) → `data` carries the block's own fields.

**Anti-patterns now rejected with 422** (used to silently 200 OK + render blank):

- `{type: "component", data: {slug: "...", props: {}}}` — move `slug` to the top-level `component_slug` field. The error message names `data.slug` and points to the fix.
- `{type: "rich_text", data: {text: "..."}}` — use `data.html` or `data.content`.
- Unknown fields on `POST/PATCH /components` (like `css_styles` instead of `css`) — the response returns 200 with a `warnings[]` array listing each ignored field + a "Did you mean X?" hint. Check the response body.
- Slug with `/` (e.g. `product/xyz`) — rejected at creation; use flat slugs like `product-xyz`. Nested doc paths use `parent_id` chains.

### Page Templates
`default` (header + footer), `landing` (full-bleed main), `blank` (no chrome at all — full canvas), `dynamic_landing` (/lp/ routes with lead data). Unknown values fall back to `default`.

### Theme Palette (NEW in v0.8.2)

6 settings fields control the site palette. Null values = default dark.

| Field | Purpose | Default |
|---|---|---|
| `primary_color` | Accent (CTAs, links, borders) | `#eebf01` |
| `surface_color` | Body / main background | `#0A0A0B` |
| `surface_elevated_color` | Card / panel background | `#111113` |
| `subtle_color` | Border / subtle bg | `#1A1A1D` |
| `body_text_color` | Default body text | `#e5e5e5` |
| `heading_color` | Headings / logo text | `#ffffff` |

Make the whole site light: set `surface_color: "#ffffff"`, `surface_elevated_color: "#f5f5f5"`, `subtle_color: "#e5e5e5"`, `body_text_color: "#18181b"`, `heading_color: "#0a0a0a"`.

### Upload Images / PDFs / Video (from a URL)
```bash
POST /api/v1/media/files/import-url
{ "url": "https://example.com/image.jpg", "folder": "/content" }
# Deterministic keys (no YYYYMMDD_HHMMSS_ prefix): pass preserve_filename
{ "url": "...", "filename": "logo.png", "preserve_filename": true, "folder": "brand" }
```

### Upload from your local filesystem — preferred for bulk (v0.9.4+)

One MCP/CLI call uploads a file or a whole directory. Scroll-sequence folders auto-optimize (Sharp → WebP q75, max 1920px) before upload, so a 120 × 1.6 MB input doesn't become a 192 MB CDN bill.

```
# MCP
upload_local_file(local_path="./logo.webp", folder="brand")
upload_local_directory(local_dir="./frames/", folder="scroll-sequences/hero")
# → auto-enables auto_optimize=true + preserve_filename=true when folder starts with "scroll-sequences/"

# CLI
spideriq media upload ./logo.webp --folder brand
spideriq media upload ./frames/ --folder scroll-sequences/hero
```

Server enforces weight policy and returns 400 with `suggested_action` if you bust it:

| Target folder | Per-file hard | Batch total hard |
|---|---|---|
| `scroll-sequences/*` | 500 KB | 20 MB |
| general | 20 MB | 500 MB |
| `video/*` MIME | 500 MB | 500 MB (single-file cap is per-file limit) |

Full recipe: **[skills/recipes/bulk-media-upload/](./skills/recipes/bulk-media-upload/SKILL.md)**

### Directory Pages (programmatic SEO, v2.89.0+)

Build a per-category + per-city + per-listing directory with SEO title/description templates that auto-interpolate `{category}`, `{city}`, `{listing}`. Every URL auto-lands in `/sitemap.xml`.

```
# 1. Create the category
directory_create_category(
  name = "Plumbers",
  seo_title_template = "Best {category} in {city} | Your Brand"
)

# 2. Drop in an IDAP dump or SpiderMaps result set (up to 5000 per call)
directory_bulk_upsert_listings(
  category_slug = "plumbers",
  listings = [{name, city, state, phone, website, rating, ...}, ...]
)
# → /directory/plumbers, /directory/plumbers/miami-beach-florida,
#   /directory/plumbers/miami-beach-florida/aqua-fix all live, sitemap updated.
```

No publish step. No deploy step. `city_slug` computed automatically from `city + state`. Full recipe: **[skills/recipes/directory/](./skills/recipes/directory/SKILL.md)** · Example: **[examples/directory-bulk-import.sh](./examples/directory-bulk-import.sh)**.

### Dynamic Landing Pages
URL: `/lp/{page_slug}/{google_place_id}` or `/lp/{page_slug}/{salesperson}/{google_place_id}`

**Use flat email-marketing merge tags** (Mailchimp/HubSpot/ActiveCampaign style — every LLM already knows them):
`{{ firstname }}`, `{{ company_name }}`, `{{ city }}`, `{{ industry }}`, `{{ rating }}`, `{{ email }}`, `{{ phone }}`, `{{ logo }}`, `{{ team_size }}`, `{{ founded }}`, `{{ revenue }}`, plus `{% for %}` arrays for `emails`, `phones`, `contacts`, `officers`, `pain_points`, `categories`. ~40 tags total.

**Full reference (read first):** [MERGE-TAGS.md](./MERGE-TAGS.md) · live at https://docs.spideriq.ai/site-builder/merge-tags/ · API: `GET /api/v1/content/variables?format=yaml` · MCP: `content_get_variables` (in `@spideriq/mcp-publish@1.0.0+` and `@spideriq/mcp@1.0.0+`).

**Preview without real data:** `/lp/{slug}/demo` — serves the built-in Mario's Pizzeria fixture with every tag populated.

Power-user: the raw `lead.*` nested shape is still in scope for fields not surfaced as merge tags. `{{ salesperson.* }}` also available when the URL includes a salesperson slug.

Ready-to-run end-to-end: [`examples/personalized-landing.sh`](./examples/personalized-landing.sh).

### Booking / Appointments (SpiderBook — cal.com-powered, v1.0.0+)

Customer-facing booking widget, standalone `/book/{flow_id}` route, and a `{% booking %}` Liquid tag for page templates. Flows are authored from the official archetype library (nail-salon, haircut, therapy, consultation, ...).

```
booking_template_list(category="nail-salon")
booking_template_clone(template_id="nail-salon-default", business_id="<uuid>", name="Downtown Bookings")
booking_flow_update(flow_id=<id>, theme={primary_color: "#e8556f"}, translations={"es": {...}})
booking_flow_publish(flow_id=<id>, dry_run=true)   → confirm_token
booking_flow_publish(flow_id=<id>, confirm_token=...) → live (provisions cal.com event type)
booking_flow_preview(flow_id=<id>)                 → /book/{flow_id}
content_deploy_site(...)                            # redeploy so /book + {% booking %} pick up the flow
```

Embed inside a page template:
```liquid
{% booking flow_id: business.booking_flow_id %}
```

Customer self-service (uses the signed `manage_token` from the confirmation email, NOT gated server-side):
```
booking_reschedule(manage_token="bkm_...", new_slot_start="2026-04-20T14:00:00Z")
booking_cancel(manage_token="bkm_...", reason="...")
```

Reads: `booking_list(business_id, status?, since?)`, `booking_get(booking_id)`. Services (what can be booked): `service_create` / `service_update` / `service_delete` (gated). All tools live in the kitchen-sink `@spideriq/mcp@1.0.0`.

**Full guide:** [skills/booking/](./skills/booking/) · **End-to-end example:** [`examples/booking-flow.sh`](./examples/booking-flow.sh).

### IDAP (CRM Data)
```bash
GET /api/v1/idap/businesses?limit=20&include=emails&format=yaml
GET /api/v1/idap/businesses/resolve?place_id=0x47e66fdad6f1cc73:0x341211b3fccd79e1
```

### Chrome auto-skip (2026-04-24)

When a page has a block that resolves to a component with `category='header'` OR `category='footer'`, the renderer now **automatically suppresses the native `{% section 'header' %}` / `'footer'`** so you don't get double chrome. Replaces three workarounds:

- Polling `nukeUI()` JS that hid native elements on setInterval
- Forcing every page to `template='blank'` and losing the layout wrapper
- Per-page conditional `copyright_text` scripts

**How to opt in:** mark your custom header/footer components with `category: "header"` or `category: "footer"` on create/update. The auto-detect fires on every page render — no settings toggle needed.

**Manual override** via the existing `custom_fields` JSONB on `content_pages` (no migration needed):

```json
{"custom_fields": {"hide_native_chrome": true}}
// granular:
{"custom_fields": {"hide_native_header": true, "hide_native_footer": false}}
```

Reference JSON: [components/page-with-custom-header.json](components/page-with-custom-header.json).

### Empty-string props now suppress defaults (2026-04-24)

Page block `props.image = ""` now correctly overrides a component's `default_props.image = "/placeholder.jpg"`. Before: LiquidJS treated `""` as truthy for `{% if props.image %}` checks, so the placeholder kept rendering. Fix: the renderer's `{% component %}` tag deletes empty-string / null props after the merge, so the Liquid template sees `props.image == nil` (falsy) and correctly falls through. Falsy-but-meaningful values (`0`, `false`) are preserved.

### Preview a single component in isolation (2026-04-24)

Before a full-site deploy, iframe-render one component to check Shadow DOM styling:

```bash
POST /api/v1/dashboard/projects/{pid}/content/components/{component_id}/preview
{ "props": { "headline": "Hello" }, "viewport": "desktop" }
# → { html, css, js, custom_element_tag, merged_props, framework?, bundle_url? }
```

The `html` is the full `<spideriq-cmp data-slug="...">` block with a declarative `<template shadowrootmode="open">` inside — drop it into `<iframe srcdoc="...">` and you have a pixel-accurate preview in ~100–300 ms instead of a 60–90 s site deploy. Full-fidelity preview still ships via `content_deploy_site_preview`.

Runnable example: [examples/preview-component.sh](examples/preview-component.sh).

### Audit internal links before deploy (2026-04-24)

One call validates every `/path` in every page's blocks + all navigation menus against the published-page roster + active redirects:

```bash
GET /api/v1/dashboard/projects/{pid}/content/audit/links
# → { valid_count, broken: [{path, source, reason}], proposed_redirects, known_redirects }
```

`source` strings describe the exact tree position (`page:home/block[2].cta_primary.url`, `navigation:header[3].url`) so you can navigate straight to the fix. `proposed_redirects` offers a 301 when a broken path's suffix matches an existing slug.

Runnable example: [examples/audit-links.sh](examples/audit-links.sh) · Full recipe: [skills/recipes/link-audit/](skills/recipes/link-audit/).

### Tilda / Webflow import — `auto_extract_css` escape hatch (2026-04-24)

By default the server rejects `<style>` blocks inside `html_template` (loud error — Shadow DOM ignores them). For Tilda/Webflow imports whose HTML is saturated with inline styles, pass `auto_extract_css: true` on `component_create` / `component_update` and the server will move every `<style>...</style>` block into the `css` field before validation.

```bash
POST /api/v1/dashboard/projects/{pid}/content/components
{
  "slug": "legacy-section",
  "name": "Ported Section",
  "html_template": "<style>.foo{color:red}</style><section>...",
  "auto_extract_css": true
}
# → server returns the normal ComponentResponse; html_template is clean, css has the rules.
```

Off by default — the explicit-over-magical contract for hand-authored components stays. Runnable example: [examples/tilda-migrate-css.sh](examples/tilda-migrate-css.sh) · Full recipe: [skills/recipes/tilda-migration/](skills/recipes/tilda-migration/).

---

## Components (Shadow DOM — 4 Tiers)

Reusable UI blocks with automatic CSS isolation. The tier is detected from which fields are present:

| Tier | Name | What to Set | Best For |
|------|------|-------------|----------|
| 1 | Static | `html_template` + `css` | Heroes, footers, content sections |
| 2 | Interactive | + `js` | Accordions, tabs, counters, toggles |
| 3 | Rich | + `dependencies` | GSAP animations, carousels, charts, scroll-scrubbed heroes |
| 4 | App | + `framework` + `source_code` | React/Vue/Svelte apps |

All destructive component operations (`publish`, `archive`, `delete`) default to `dry_run=true` in MCP — call twice with `confirm_token` to actually mutate.

### Site-wide component changes — use the one-shots (v2.88.0+)

When a component is used on multiple pages and you want to update it site-wide, do NOT run `component_update` + N × `content_update_page` calls. Use the one-shot:

```
component_update_and_propagate(slug="hero", css=<new css>, dry_run=true)
# → returns confirm_token + affected_pages list
component_update_and_propagate(slug="hero", css=<new css>, confirm_token="cft_...")
# → bumps component version, repoints every consuming page's block pin, all in one transaction
```

Add `pages: ["home"]` to stage the rollout (other pages keep their old pin). Block-level page content renders live via the content API on next request — NO tenant deploy needed.

If something breaks, undo is also one call:

```
component_rollback(slug="hero", target_version="1.4.0", dry_run=true)
# → preview; then re-run with confirm_token
```

Rollback creates a new forward version with the target version's content (immutable history). Full recipes: [skills/recipes/component-update-and-propagate/](skills/recipes/component-update-and-propagate/) + [skills/recipes/component-rollback/](skills/recipes/component-rollback/).

### Create a Component
```bash
POST /api/v1/dashboard/projects/{pid}/content/components
{ "slug": "hero-gradient", "name": "Gradient Hero", "category": "hero",
  "html_template": "<section><h1>{{ props.headline }}</h1></section>",
  "css": "section { background: linear-gradient(135deg, var(--primary), var(--surface)); padding: 5rem 2rem; color: var(--heading); }",
  "props_schema": { "type": "object", "properties": { "headline": { "type": "string" } }, "required": ["headline"] } }
```

### Add JavaScript (Tier 2)
```json
{ "js": "root.querySelector('button').addEventListener('click', () => { /* ... */ });" }
```
JS receives `root` (shadowRoot) and `props`. Use `root.querySelector()`, never `document.querySelector()`. Never use JS to modify site chrome — use `content_override_section` instead.

### Add CDN Libraries (Tier 3)
```json
{ "dependencies": ["gsap", "gsap/ScrollTrigger"], "js": "gsap.registerPlugin(ScrollTrigger); /* ... */" }
```
Available: `gsap`, `gsap/ScrollTrigger`, `gsap/Flip`, `animejs`, `alpinejs`, `chartjs`, `lottie`, `swiper`, `countup`, `three`. Check `GET /content/cdn-allowlist`. **Framer Motion is NOT allowlisted** (React-only — use Tier 4 if you need it).

### Framework Components (Tier 4)
```json
{ "framework": "react", "source_code": "import React from 'react';\nexport default function App(props) { return <h1>{props.headline}</h1>; }" }
```
Publish returns 202 (async build). Poll `GET .../build-status` until `success`.

### Use in Pages
```json
{ "type": "component", "component_slug": "hero-gradient", "props": { "headline": "Welcome" } }
```

### Scroll-Linked Hero (image sequence) — use `sys-scroll-sequence`

**Do NOT build your own scroll-sequence component.** The global `sys-scroll-sequence` (Tier 3, is_global=true, already published) handles canvas setup, GSAP wiring, and progressive preloading. Feed it frames from a SpiderVideo `extract_frames` job:

```
1. Upload source video → https://media.cdn.spideriq.ai/.../source.mp4
2. Submit spiderVideo extract_frames job with target_frames=120, output_format=webp
3. Poll until completed → grab {base_url, pattern, count} from the manifest
4. Add block to a page:
   { type: "component",
     component_slug: "sys-scroll-sequence",
     props: { base_url, pattern, count,
              scroll_distance_vh: 400,
              preload_strategy: "progressive" } }
5. content_deploy_site_preview → content_deploy_site_production(confirm_token)
```

Runnable script: **[examples/scroll-sequence.sh](examples/scroll-sequence.sh)**
Block config reference: **[components/scroll-sequence.json](components/scroll-sequence.json)**
Full recipe skill (Tier 1/2/3): **[skills/recipes/scroll-sequence/](skills/recipes/scroll-sequence/)**

Anti-patterns that waste 12 hours of agent time:
- Hardcoding 100+ frame URLs → CDN rate-limits → "flashlight strobe" of black frames
- Tunneling local frames through pinggy/serveo into `/media/files/import-url` → tunnels inject HTML interstitials saved as `.webp`
- Rolling your own scroll component with GSAP when `sys-scroll-sequence` already does it

### Upload Many Local Files

One MCP/CLI call handles files or directories — see the **"Upload from your local filesystem"** section above. Scroll-sequence folders auto-optimize to WebP so a 120-frame × 1.6 MB input (192 MB, doomed) becomes ~8 MB that first-paints fast.

Recipe: **[skills/recipes/bulk-media-upload/](skills/recipes/bulk-media-upload/SKILL.md)** · Example: **[examples/bulk-media-upload.sh](examples/bulk-media-upload.sh)**

Do NOT use `/media/files/import-url` with a localhost tunnel — it's the #1 cause of silent-failure deploys (tunnels inject HTML interstitials that land as `.webp`).

### Component Examples
Ready-to-POST examples in `components/`:
- `hero-gradient.json` — Tier 1: gradient hero
- `pricing-cards.json` — Tier 1: 3-tier pricing
- `faq-accordion.json` — Tier 2: interactive FAQ accordion
- `stats-animated.json` — Tier 3: GSAP animated stats counter
- `pricing-toggle.json` — Tier 4: React pricing with monthly/annual toggle
- `scroll-sequence.json` — **reference**: page-block config for the global `sys-scroll-sequence` component (not a create body — feed it from `extract_frames`)

---

### Rate Limits
- API: 100 requests/minute
- Jobs: 10 submissions/minute
- Always use `?format=yaml` (saves 40-76% tokens)

## Marketplace V2 — find sections by intent (May 2026)

**The shipped pivot.** The classic `content_list_marketplace_components` filters by `category` (hero, features, pricing, …). Six new tools turn the same catalog into something you search by **what an agent actually wants** — "calm cinematic for a luxury hotel," "energetic conversion-focused for ecommerce" — across all 3 marketplace tables (bg-videos / components / site-templates) in one query.

```
marketplace_search(
  mood = ["calm"],
  asset_types = ["bg_video"],
  limit = 5
)
# → results: [{slug, asset_type, mood, scene_type, video_url|preview_thumbnail_url, ...}]
```

| Tool | Auth | Use case |
|---|---|---|
| `marketplace_search` | public | Cross-table search by mood / palette / brand_fit_tags / scene_type / agent_meta / asset_types |
| `list_data_sources` | public | Discover available source IDs for binding `kind="dynamic"` blocks (posts, authors, IDAP×4, idap.lead) |
| `marketplace_suggest_agent_meta` | super_admin | **NEW (1.7.0)** Suggest mood/palette/brand_fit/scene_type/agent_meta for one asset via the SpiderGate inference engine. Pure read — no DB write. Then review + apply via `set_*_agent_meta`. |
| `set_component_kind` | gated | Promote a custom component into the 4-class taxonomy (`static / interactive / dynamic / extension`) |
| `set_component_agent_meta` | gated | Curate axes + ComponentAgentMeta on a component so other agents can find it |
| `set_bg_video_agent_meta` | super_admin, gated | Curate bg-video discoverability (pace, time_of_day, weather, aspect_ratio, …) |
| `set_site_template_agent_meta` | super_admin, gated | Curate site-template discoverability (page_count, has_blog, style_aesthetic, …) |

**Two-step suggest → apply flow (NEW in 1.7.0):**

```
1. marketplace_suggest_agent_meta(asset_type="bg_video", slug="alpine-wildflowers")
   → SuggestEnvelope: { proposed_universal_axes, proposed_agent_meta,
                         confidence_per_key (action: auto_apply | review | drop),
                         dropped_keys (off-vocab), reasoning, usage }

2. Review the envelope — for values you trust:
   set_bg_video_agent_meta(slug="alpine-wildflowers",
                            mood=["calm","dreamy"], scene_type="nature-landscape",
                            agent_meta={pace: "slow", time_of_day: "day", ...})
   → gated: dry_run=true default; second call with confirm_token to apply
```

The engine validates against locked Pydantic enums BEFORE returning — off-vocab values are dropped (not stored). Confidence thresholds: ≥0.75 = auto_apply, ≥0.55 = review, else drop. Apply tools mark the row `agent_meta_source='llm_inferred'` so future bulk re-runs distinguish machine suggestions from human curation.

**CLI mirrors:** `npx @spideriq/cli marketplace search`, `... marketplace help`, `... marketplace suggest <type> <slug>`, `... sources list`, `... bg-videos set-meta`, `... content components set-kind`, `... content components set-meta`.

**Vocabulary (subset):**

| Axis | Values |
|---|---|
| `mood` | calm, energetic, bold, confident, dreamy, futuristic, urban, minimal, warm, sensory, editorial, professional, friendly, clear, technical, credible |
| `brand_fit_tags` | saas, agency, ecommerce, fintech, hospitality, restaurant, wellness, healthcare, blog, publication, real-estate, … |
| `scene_type` | hero-bold, conversion-cta, social-proof (components); city-aerial, nature-landscape (bg-videos); marketing-site, docs-site (site-templates) |

Full vocab + per-asset `agent_meta` keys (BgVideoAgentMeta / ComponentAgentMeta / SiteTemplateAgentMeta): [skills/content-platform/schema.yaml](skills/content-platform/schema.yaml) under `marketplace_v2_axes:`. Or call `template_get_help` (returns the canonical YAML reference).

**Recipes:**
- [skills/recipes/marketplace-search-and-insert/](skills/recipes/marketplace-search-and-insert/) — Find a marketplace asset by intent, insert it into a page (May 2026)
- [skills/recipes/marketplace-suggest-agent-meta/](skills/recipes/marketplace-suggest-agent-meta/) — **NEW (1.7.0)** Suggest metadata for a newly uploaded asset, then apply via `set_*_agent_meta`

## Skills — Curated Recipes

Multi-step workflows that compose MCP tools. Live at **[skills/](skills/)** in this starter kit.

**Core building blocks** (exposed via `@spideriq/mcp-publish` — these SKILL.md files are the human/agent reference):
- [content-platform](skills/content-platform/) — Pages, posts (with authors/tags/categories), docs, nav, settings, components, **directory pages**, component site-wide propagation, section overrides
- [booking](skills/booking/) — **Appointments / bookings** powered by cal.com. Flow authoring, services, bookings, template library. Ships a `/book/{flow_id}` route + `{% booking %}` Liquid tag (in `@spideriq/mcp@1.0.0` kitchen-sink)
- [templates-engine](skills/templates-engine/) — Liquid templates, themes, deploy to edge
- [upload-host-media](skills/upload-host-media/) — Media upload to CDN (including local-filesystem `upload_local_file` / `_directory`)
- [agentdocs](skills/agentdocs/) — Versioned docs projects

**Recipes** (Tier 1 YAML doc + Tier 2 MCP-call schema + Tier 3 TypeScript impl that runs anywhere):
- [recipes/scroll-sequence](skills/recipes/scroll-sequence/) — Video → frames → `sys-scroll-sequence` → deploy
- [recipes/preview-iteration](skills/recipes/preview-iteration/) — Edit → preview → browser-check → confirm_token → production
- [recipes/bulk-media-upload](skills/recipes/bulk-media-upload/) — Local directory → R2 (no tunnels needed)
- [recipes/directory](skills/recipes/directory/) — Category → bulk-upsert listings (or IDAP import) → deploy → programmatic SEO pages live
- [recipes/component-update-and-propagate](skills/recipes/component-update-and-propagate/) — Safe site-wide component change in one call
- [recipes/component-rollback](skills/recipes/component-rollback/) — Unroll a bad component change
- [recipes/link-audit](skills/recipes/link-audit/) — Find broken internal links across pages + nav before deploy (2026-04-24)
- [recipes/tilda-migration](skills/recipes/tilda-migration/) — Port a Tilda site with `auto_extract_css` + flat slugs + `category='header'|'footer'` components (2026-04-24)
- [recipes/marketplace-search-and-insert](skills/recipes/marketplace-search-and-insert/) — Find a marketplace asset by intent (mood/palette/brand-fit/scene), insert it into a page (2026-05-05)
- [recipes/marketplace-suggest-agent-meta](skills/recipes/marketplace-suggest-agent-meta/) — Suggest metadata for a freshly uploaded asset via the SpiderGate inference engine, then apply via the gated `set_*_agent_meta` tools (2026-05-06)

Tier 3 `impl.ts` files use only Node 18+ stdlib (`fetch`, `fs`, `path`) — zero npm dependencies. Copy-paste them into your agent's sandbox and run with `npx tsx impl.ts`. No extra runtime required.

## Tutorials
- [Build a Homepage](https://docs.spideriq.ai/site-builder/tutorial-homepage)
- [Build a Blog](https://docs.spideriq.ai/site-builder/tutorial-blog)
- [Personalized Landing Page](https://docs.spideriq.ai/site-builder/tutorial-dynamic-landing)

## Full Documentation
- [AI Agent Guide](https://docs.spideriq.ai/site-builder/agents)
- [Session Binding](https://docs.spideriq.ai/site-builder/sessions)
- [Deploy Safely](https://docs.spideriq.ai/site-builder/deploy-safely)
- [Component Builder Guide](https://docs.spideriq.ai/site-builder/component-builder)
- [Component Tiers Reference](https://docs.spideriq.ai/site-builder/component-tiers)
- [Component Agent Reference](https://docs.spideriq.ai/site-builder/component-agents-reference)
- [Gotchas & Best Practices](https://docs.spideriq.ai/site-builder/learnings)
- [Deploy Guide](https://docs.spideriq.ai/site-builder/deployment)
- [API Reference](https://docs.spideriq.ai/api-reference/introduction)

---

## Skills bundled with this kit

### Recipes (multi-step workflows)

- [Build a Scroll-Linked Hero from a Video](.cursor/rules/scroll-sequence.mdc) — Build a cinematic scroll-scrubbed hero from a video file using ffmpeg frame extraction and the sys-scroll-sequence component.
- [Search the SpiderIQ Component Marketplace](.cursor/rules/marketplace-search-and-insert.mdc) — Search the curated SpiderIQ component marketplace by kind / mood / palette / brand_fit_tags / scene_type, then insert a result into a page.
- [Suggest agent_meta for Marketplace Assets (LLM-Inferred)](.cursor/rules/marketplace-suggest-agent-meta.mdc) — Use the SpiderGate-powered marketplace_suggest_agent_meta tool to infer mood / palette / brand_fit_tags / scene_type / agent_meta for a marketplace asset (component, bg-video, site template).
- [Update a Shared Component and Propagate Across All Pages](.cursor/rules/component-update-and-propagate.mdc) — Update a shared component AND repoint every consuming page's block pin in one MCP call + one confirm_token (v2.
- [Roll Back a Shared Component to an Earlier Version](.cursor/rules/component-rollback.mdc) — Restore a component to an earlier version's content.
- [Safe Edit Loop with Preview → Confirm](.cursor/rules/preview-iteration.mdc) — Iterate on a page or template safely: template_preview (no state mutation) → browser-check → publish (dry_run → confirm_token).
- [Upload a Local Directory of Files via Multipart POST](.cursor/rules/bulk-media-upload.mdc) — Upload a local directory of files directly via multipart POST.
- [Build a Programmatic Directory (Category / City / Listing)](.cursor/rules/directory.mdc) — Build /directory/{category}/{city}/{listing} pages programmatically: create category → bulk-upsert listings (or import from IDAP) → deploy.
- [Audit Internal Links Before Deploy](.cursor/rules/link-audit.mdc) — Scan the tenant's published surface for broken internal links (404s, redirects, mistyped slugs) before deploy.
- [Migrate a Tilda / Webflow / Lovable Site to SpiderPublish](.cursor/rules/tilda-migration.mdc) — End-to-end migration from a Tilda export (or Webflow / Lovable export): section → component → page → publish, with auto_extract_css for one-file imports.

### Core MCP-namespace skills

- [SpiderPublish Content Platform — Full MCP Surface](.cursor/rules/content-platform.mdc) — Full content_* / directory_* / playbook_* MCP namespace overview: pages, posts, docs, navigation, settings, components, domains, directory pages, component site-wide propagation, section overrides.
- [SpiderBook — Appointment-Booking MCP Surface](.cursor/rules/booking.mdc) — Full booking_* MCP namespace: cal.
- [Liquid Templates + Themes + Edge Deploy](.cursor/rules/templates-engine.mdc) — template_* / content_deploy_site_* MCP surface for Liquid templates, themes, and Cloudflare edge deploy.
- [SpiderMedia — Image / File / Video Upload](.cursor/rules/upload-host-media.mdc) — media_* MCP namespace: upload images, files, videos to the SpiderMedia CDN.
- [AgentDocs — Versioned Documentation Projects](.cursor/rules/agentdocs.mdc) — agentdocs_* MCP namespace: build versioned documentation projects (Mintlify-style) with sidebar config, MDX pages, full-text search, and edge deploy.

### Guides (onboarding + decision aids)

- [Create a SpiderIQ Tenant Page](.cursor/rules/create-page.mdc) — Create a new published page on a SpiderIQ tenant via the @spideriq/mcp-publish MCP server.
- [Build a SpiderIQ Personalized Landing Page](.cursor/rules/personalized-landing.mdc) — Build a personalized landing page via /lp/{slug}/{place_id} with merge tags fed by IDAP.
- [Pick the Right @spideriq/mcp-* Package](.cursor/rules/pick-mcp-package.mdc) — Decide which @spideriq/mcp-* npm package to install.
- [@spideriq/cli Quick Reference](.cursor/rules/cli-quick-reference.mdc) — Run SpiderIQ from the terminal via @spideriq/cli — auth flow, project binding, pages CRUD, marketplace search, deploy, output formats.
- [Install + Set Up the SpiderPublish IDE Extension](.cursor/rules/ide-extension-setup.mdc) — Install + bind the SpiderPublish IDE extension (SpiderIQ.
