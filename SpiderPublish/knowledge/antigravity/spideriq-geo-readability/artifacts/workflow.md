# Make a SpiderIQ Tenant Page LLM-Readable (GEO)

When the user asks about AI-search SEO, GEO, llms.txt, schema.org, or "make my site discoverable by ChatGPT/Claude/Perplexity", execute these steps.

## Step 1: read the GEO reference

Open [SpiderPublish/GEO.md](../../../GEO.md). It documents the six extensions (W6.1, W6.2, W6.3, W7.1, W7.2, W7.3) and seven endpoints. Note the naming clarification: `sys-geo-*` = **Generative Engine Optimization**, NOT geographic.

## Step 2: pick which extensions match the site shape

Don't enable all six blindly. Match to the site:

| Site has… | Enable |
|---|---|
| Blog or posts | W6.1 (RSS/Atom/JSON feeds) |
| Any published content | W6.2 (sitemap + robots), W6.3 (llms.txt) |
| Articles, products, FAQs, events | W7.2 (schema.org JSON-LD) |
| Wants to override right-click for LLM users | W7.1 (contextual menu) |
| Wants explicit "human view / agent view" toggle | W7.3 (geo_toggle_enabled) |

Default recommendation for an agency-built tenant: **W6.2 + W6.3 + W7.2** (sitemap, llms.txt, schema injection). The other three are case-by-case.

## Step 3: pick the llms.txt preset (W6.3)

| Preset | When |
|---|---|
| `minimal` | Static brochure site, no blog/docs |
| `blog-only` | Marketing site with blog |
| `fastapi-style` | Developer / API-product site |
| `mintlify` | Documentation-heavy site |

## Step 4: PATCH content_settings.extensions

Single call enables everything:

```
content_update_settings({
  geo_toggle_enabled: true,             // W7.3 (top-level, NOT under extensions)
  extensions: {
    feeds:           { enabled: true, title: "<Site> Blog", items: 20 },
    sitemap:         { enabled: true, include_pages: true, include_posts: true, include_docs: true, lastmod_strategy: "updated_at" },
    robots:          { enabled: true, allow_all: true, disallow_paths: ["/admin", "/private"], extra_lines: ["Sitemap: https://<domain>/sitemap.xml"] },
    opensearch:      { enabled: true, short_name: "<Site>", description: "Search <Site>", search_url_template: "/search?q={searchTerms}" },
    llms_txt:        { enabled: true, preset: "blog-only", title: "<Site> Knowledge", summary: "<one-line site summary>" },
    contextual_menu: { enabled: true, actions: { copy_md: true, copy_jsonld: true, open_chatgpt: true, open_claude: true } },
    schema_defaults: { enabled: true, site_type: "Organization", always_emit_breadcrumb_list: true, always_emit_organization: true }
  },
  dry_run: true
})
content_update_settings({ ..., confirm_token: "cft_..." })
```

## Step 5: per-page schema overrides (W7.2)

For high-value pages (articles, product pages), set page-specific schema:

```
content_update_page({
  page_id,
  metadata: {
    schema_type: "Article",
    schema_props: {
      headline: "...",
      datePublished: "2026-05-08",
      author: { "@type": "Person", "name": "..." },
      image: "https://..."
    }
  }
})
```

The injector reads `metadata.schema_props` and emits `<script type="application/ld+json">` into `<head>` at render time.

## Step 6: deploy

Standard deploy flow. The endpoints become live the moment the deploy completes.

## Step 7: verify

```
curl -s https://<tenant-domain>/llms.txt | head -20
curl -s https://<tenant-domain>/sitemap.xml | head -20
curl -s https://<tenant-domain>/feed.xml | head -20
curl -s https://<tenant-domain>/robots.txt
curl -s https://<tenant-domain>/<some-page> | grep -A 5 "application/ld+json"
```

All five should return non-empty content.

## Don't

- **Enable `feeds` on a site with no blog posts** — generates an empty feed that crawlers downrank.
- **Set `geo_toggle_enabled: false` from the dashboard's generic save handler** — it has a known boolean-collapse bug; use the dedicated handler. See [LEARNINGS.md](../../../LEARNINGS.md).
- **Skip the per-page `schema_props` for articles** — site-wide `schema_defaults` only emits Organization + BreadcrumbList; Article-level schema needs per-page setup to actually rank.
- **Confuse with geographic features.** `dynamic-map` blocks, IDAP lat/lng, and address autocomplete are unrelated to the W6+W7 GEO family.
