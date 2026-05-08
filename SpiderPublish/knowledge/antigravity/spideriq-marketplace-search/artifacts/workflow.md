# Search the SpiderIQ Component Marketplace

When the user asks for a section, block, or component, execute these steps.

## Step 1: identify the kind

Before searching, narrow by the 4-class taxonomy:

- `static` — pure presentation (hero, FAQ, pricing card)
- `interactive` — needs JS sandbox (timer, popup, slider)
- `dynamic` — needs data binding (table, chart, list, item_details)
- `extension` — renderer hook (RSS, sitemap, schema.org, llms.txt)

Most user requests are `static` (heroes, CTAs, pricing tables, testimonials). If the user wants "live data", "auto-updating", "linked to my CRM", they want `dynamic`. If the user wants "a popup", "a timer", "exit-intent", they want `interactive`.

## Step 2: call marketplace_search

```
marketplace_search({
  kind: "static",                       // optional, narrows by class
  block_type: "hero",                   // optional, e.g. hero, cta, pricing
  mood: ["bold", "minimal"],            // optional, vocabulary at /content/help
  palette: ["dark", "neutral"],         // optional, semantic colors
  brand_fit_tags: ["saas", "agency"],   // optional, brand persona
  scene_type: "landing"                 // optional, layout intent
})
```

Returns a list with `{slug, name, description, preview_thumbnail_url, props_schema, agent_meta, replication_prompt}` per asset.

## Step 3: review the candidates

Read `description` and `agent_meta` for each result. The `replication_prompt` field tells you exactly how to recreate the component if you need to fork it — useful for "make me one like X but with Y change".

## Step 4: insert the chosen component into the target page

```
content_insert_section_into_page({
  page_id: "...",
  component_slug: "<chosen-slug>",
  position: "end",                      // or "start" / "before:<block_id>" / "after:<block_id>" / <int>
  props: { /* override default props if needed */ },
  dry_run: true
})
// returns { preview, confirm_token }
content_insert_section_into_page({ ..., confirm_token: "cft_..." })
```

## Step 5: deploy

The standard `content_deploy_site_preview` → `content_deploy_site_production` → `content_deploy_status` flow.

## When the marketplace doesn't have what you need

If `marketplace_search` returns nothing useful, use `marketplace_suggest_agent_meta` on a freshly uploaded asset to LLM-suggest mood / palette / brand_fit_tags / scene_type / agent_meta — the suggestions get reviewed and applied via the `set_*_agent_meta` tools so the asset becomes searchable. See [skills/recipes/marketplace-suggest-agent-meta/](../../../skills/recipes/marketplace-suggest-agent-meta/).

## Anti-patterns

- **Inserting an `extension` component as a page block.** Extensions configure via `content_settings.extensions.*`, not in `blocks[]`. Use the `spideriq-geo-readability` KI for that path.
- **Searching without a `kind` filter when the user wants something specific.** Returns hundreds of results across classes; narrow first.
- **Ignoring `props_schema`.** Each component declares its props with zod-validated types; passing wrong props returns 422.
