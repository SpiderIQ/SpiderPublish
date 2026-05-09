# SpiderPublish — GEO.md

> Generative Engine Optimization. Make every published tenant page first-class for AI search (ChatGPT, Claude, Perplexity, Google AI Overviews) without writing custom code. Six extensions, seven endpoints, configured via `content_settings.extensions`.

---

## Naming clarification (read this first)

The platform uses two unrelated concepts that share the prefix `geo`:

| Term | Meaning | Lives in |
|---|---|---|
| **GEO / `sys-geo-*`** | **Generative Engine Optimization** — making pages legible to LLM crawlers and AI search engines | `content_settings.extensions.*`, [`components/extension-*.json`](./components/), [`components/tenant-setting-geo-toggle.json`](./components/tenant-setting-geo-toggle.json) |
| **Geographic data** | Lat/lng/country, address autocomplete, city directories, business hours | [`components/dynamic-map.json`](./components/dynamic-map.json), IDAP scraping pipeline, `directory_*` tools, phone-validated form fields |

These are not connected. The `sys-geo-*` prefix in the marketplace is short for "Generative Engine Optimization." A `dynamic-map` block at `/contact` and an `extensions.contextual_menu` toggle on `/blog/article` solve different problems.

---

## The W6 + W7 family — one table

Six extensions, seven endpoints. All ship as renderer-hooks or page-injections — none requires a page-block in `content_pages.blocks[]`. Toggle each via `content_settings.extensions.<key>.enabled`.

| Wave | Slug / file | What it ships | Endpoint(s) | `content_settings` key |
|---|---|---|---|---|
| **W6.1** | [extension-rss-feeds.json](./components/extension-rss-feeds.json) | RSS 2.0 + Atom 1.0 + JSON Feed 1.1 of published posts | `/feed.xml` · `/atom.xml` · `/feed.json` | `extensions.feeds` |
| **W6.2** | [extension-sitemap-robots.json](./components/extension-sitemap-robots.json) | Auto sitemap.xml of pages + posts + docs; robots.txt with allow / disallow / extras | `/sitemap.xml` · `/robots.txt` | `extensions.sitemap`, `extensions.robots` |
| **W6.3** | [extension-opensearch-llms.json](./components/extension-opensearch-llms.json) | Browser OpenSearch registration + an LLM-crawler-friendly `/llms.txt` summary (4 presets) | `/opensearch.xml` · `/llms.txt` | `extensions.opensearch`, `extensions.llms_txt` |
| **W7.1** | [extension-contextual-menu.json](./components/extension-contextual-menu.json) | Right-click menu override: Copy as MD / Copy as JSON-LD / Open in ChatGPT / Open in Claude. `Cmd+Shift+RightClick` falls through to native menu | (page-injection on every page) | `extensions.contextual_menu` |
| **W7.2** | [extension-schema-injector.json](./components/extension-schema-injector.json) | Schema.org JSON-LD into every page's `<head>`. 6 schema types: `Article`, `Product`, `FAQPage`, `Event`, `BreadcrumbList`, `Organization` | (head-injection on every page) | `extensions.schema_defaults` + per-page `metadata.schema_props` |
| **W7.3** | [tenant-setting-geo-toggle.json](./components/tenant-setting-geo-toggle.json) | Per-tenant top-level boolean. When ON, every rendered page exposes a "human view / agent view" switcher between styled HTML and Markdown projection | (page-injection — switcher widget) | `geo_toggle_enabled` (top-level, **not** under `extensions.*`) |

**Minimum renderer version:** v2.78.0 across all six.

**LLMs.txt presets** (W6.3) — pick the one that matches your site shape:

| Preset | What it includes |
|---|---|
| `minimal` | Site title + summary + top-level URLs only |
| `blog-only` | Adds every published blog post (title + URL + 1-line excerpt) |
| `fastapi-style` | Adds every public API endpoint with curl examples |
| `mintlify` | Adds every documentation page in a tree-walk format |

---

## Worked example — one tenant page, all six extensions ON

Configuration:

```jsonc
// PATCH /api/v1/dashboard/content/settings
{
  "geo_toggle_enabled": true,
  "extensions": {
    "feeds":            { "enabled": true, "title": "Acme Blog", "items": 20 },
    "sitemap":          { "enabled": true, "include_pages": true, "include_posts": true, "include_docs": true, "lastmod_strategy": "updated_at" },
    "robots":           { "enabled": true, "allow_all": true, "disallow_paths": ["/admin", "/private"], "extra_lines": ["Sitemap: https://acme.com/sitemap.xml"] },
    "opensearch":       { "enabled": true, "short_name": "Acme", "description": "Search Acme docs", "search_url_template": "/search?q={searchTerms}" },
    "llms_txt":         { "enabled": true, "preset": "blog-only", "title": "Acme Knowledge", "summary": "Acme product docs + engineering posts." },
    "contextual_menu":  { "enabled": true, "actions": { "copy_md": true, "copy_jsonld": true, "open_chatgpt": true, "open_claude": true } },
    "schema_defaults":  { "enabled": true, "site_type": "Organization", "always_emit_breadcrumb_list": true, "always_emit_organization": true }
  }
}
```

What each visitor type sees on `https://acme.com/blog/launch-day`:

| Visitor | What's served |
|---|---|
| **Human in a browser** | Styled HTML + a small "Read as agent" button injected by W7.3 + a custom right-click menu (W7.1). All visible chrome. |
| **Human, right-clicks "Copy as MD"** | Markdown projection of the page (same content, no chrome) — pasted into a chat with Claude / ChatGPT. |
| **LLM crawler** (GPTBot, ClaudeBot, PerplexityBot) | Fetches `/llms.txt` first → site summary + every blog post URL. Then fetches `/blog/launch-day` → HTML with W7.2 JSON-LD `Article` block in `<head>`. |
| **Google bot** | Fetches `/sitemap.xml` (W6.2) → all pages/posts/docs. Fetches `/feed.xml` (W6.1) → 20 newest posts. Fetches the page → HTML + JSON-LD (W7.2). |
| **RSS reader** | `/feed.xml` (W6.1). |
| **Browser with site-search** | `/opensearch.xml` (W6.3) registers the site as a searchable engine in the address bar. |

No code. No per-page markup. All of this comes from one PATCH on `content_settings`.

---

## Why this is differentiated

Most CMSs ship one or two of these (sitemap is universal; RSS is common). Shipping all six as **per-tenant toggles**, version-pinned to a renderer minimum, with consistent shapes under `extensions.*`, is uncommon. The categories that matter for AI-search readability — `/llms.txt`, JSON-LD, contextual menu, human/agent toggle — are not table stakes anywhere else today.

The shape is also stable for crawlers: every published tenant exposes the same endpoint set with the same content type, regardless of theme or component library. An LLM building a tenant site for a client gets these endpoints "for free" the moment the client publishes anything.

---

## What this is NOT

- **Not geographic.** See the [Naming clarification](#naming-clarification-read-this-first) above. Address autocomplete, lat/lng, country codes — all live elsewhere in the kit.
- **Not a substitute for content quality.** `/llms.txt` and JSON-LD make existing content discoverable to LLM crawlers; they don't generate it.
- **Not a backlink / SERP / keyword strategy.** Traditional SEO tools handle that surface. GEO is the on-page readability layer for AI engines.
- **Not always-on.** Each of the six toggles is `enabled: false` by default for new tenants. Turn on the ones that match the site's shape (e.g. don't enable `feeds` on a site with no blog).

---

## Where to next

| If you want to… | Read |
|---|---|
| Pick which surface to drive these toggles from | [SURFACES.md](./SURFACES.md) |
| Look up the full capability index | [CAPABILITIES.md](./CAPABILITIES.md) |
| Apply the toggle via MCP | `content_update_settings` in [AGENTS.md](./AGENTS.md) |
| Apply the toggle via CLI | `npx @spideriq/cli content settings set --key extensions.feeds.enabled --value true` |
| Avoid the boolean-save trap when toggling W7.3 from the dashboard | [LEARNINGS.md](./LEARNINGS.md) — search "Settings dashboard handleSave collapses boolean false to undefined" |
