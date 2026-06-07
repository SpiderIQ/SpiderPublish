# SpiderPublish — CAPABILITIES.md

> Read first. The single index of what SpiderIQ can do today, the 4-class component taxonomy that organizes it, and what's reachable from this kit vs. what lives elsewhere.

**Category:** AI-Native Agency OS — the agency stack as one runtime: CMS · CRM · workflows · booking · CRO · personalization · scraping · media. MCP-native end-to-end. Every published tenant page dual-rendered for humans and LLMs.

**This kit (`SpiderPublish/`) covers the content + extension slice.** Other slices (lead-gen, mail, gate, super-admin) ship from separate kits or via the dashboard.

---

## The 11 capability surfaces

| # | Surface | What it does | Reachable from this kit? |
|---|---------|--------------|--------------------------|
| 1 | 4-class component taxonomy | `static` / `interactive` / `dynamic` / `extension` — drives renderer + editor + agent surface | ✓ via `components/*.json` references + `marketplace_search` |
| 2 | Dynamic pages + merge tags | `/lp/{slug}/{place_id}` URL pattern with IDAP-backed personalization tokens | ✓ [MERGE-TAGS.md](./MERGE-TAGS.md), [examples/personalized-landing.sh](./examples/personalized-landing.sh) |
| 3 | Directories for lead-gen programmatic SEO | `/directory/{cat}/{city}/{listing}` fed by IDAP scraping | ✓ [skills/recipes/directory/](./skills/recipes/directory/), [examples/directory-bulk-import.sh](./examples/directory-bulk-import.sh) |
| 4 | SpiderBook — appointment-booking flows | self-hosted cal.com-backed engine + `{% booking %}` Liquid tag | ✓ [skills/booking/](./skills/booking/), [examples/booking-flow.sh](./examples/booking-flow.sh) |
| 5 | CRM (leads / contacts / pipelines) | IDAP-fed lead store, dashboard for human curation | dashboard surface; not in this kit |
| 6 | Workflows | distributed orchestration over the worker fleet for campaigns + lead pipelines | dashboard / future kit; not exposed here |
| 7 | CRO tools (interactive class) | timer · exit-intent popup · social-proof toast · stock bar · sticky bar · pricing toggle · 21-card library | ✓ via `marketplace_search` |
| 8 | GEO (W6+W7 extensions) | llms.txt · md-mirror · schema-injector · contextual-menu · human/agent toggle · sitemap · RSS · per-page index control (a page's `robots` field gates its inclusion in both `sitemap.xml` and `llms.txt`) | ✓ [GEO.md](./GEO.md), `components/extension-*.json` |
| 9 | Scraping + enrichment (data foundation) | SpiderSite · SpiderMaps · SpiderPeople · SpiderVerify · SpiderPhone · SpiderBrowser · IDAP (~44k cities) | feeds personalization + directories; jobs trigger via dashboard |
| 10 | Media services | upload / download / stream · R2-backed `media.cdn.spideriq.ai` · ffmpeg pipeline → scroll-sequence frames · **read catalog** (list / search / fetch every hosted asset across all storage tiers) | ✓ [skills/upload-host-media/](./skills/upload-host-media/), [examples/bulk-media-upload.sh](./examples/bulk-media-upload.sh), [examples/scroll-sequence.sh](./examples/scroll-sequence.sh), [examples/media-catalog-list.sh](./examples/media-catalog-list.sh) |
| 11 | Agent surface (CLI / MCP / IDE extension / Skills) | four ways to drive the runtime; same engine, different rendering | ✓ [SURFACES.md](./SURFACES.md) |

---

## The 4-class component taxonomy

Every published component is one of four kinds. The `kind` axis answers four questions before you pick a slug: does it take props? does it bind data? does it need a sandbox? does it need keys?

| Kind | Props? | Reads data? | Renders where? | Examples (slugs you can search / insert) |
|------|--------|-------------|----------------|------------------------------------------|
| `static` | ✓ | – | component HTML | `hero-gradient`, `pricing-cards`, `faq-accordion`, `stats-animated`, `pricing-toggle` |
| `interactive` | ✓ | – | HTML + JS in Shadow DOM | `sys-timer-fixed-date`, `sys-popup-exit-intent`, `sys-bar-promo` |
| `dynamic` | ✓ | ✓ | HTML + server-aggregated fetch | `dynamic-form`, `dynamic-table`, `dynamic-chart`, `dynamic-map`, `dynamic-gallery`, `dynamic-calendar`, `list`, `item_details` |
| `extension` | ✓ | ✓ | renderer / hook / tenant-side endpoint | `sys-geo-md-mirror`, `sys-rss-feed`, `sys-geo-schema-injector`, `sys-geo-contextual-menu`, `sys-sitemap-robots`, `sys-opensearch-llms`, `sys-geo-human-agent-toggle` |

**Search within a kind:** `marketplace_search` accepts `kind`, `block_type`, `mood`, `palette`, `brand_fit_tags`, `scene_type`. See [skills/recipes/marketplace-search-and-insert/SKILL.md](./skills/recipes/marketplace-search-and-insert/SKILL.md).

**Reference manifests:** every `dynamic-*` and `extension-*` block_type has a JSON manifest in [`components/`](./components/) — the canonical shape an agent reads to know what props/layouts/sources/data_binding exist.

**Why it matters for agents:** before recommending a component, identify the `kind`. A `dynamic` block needs a `data_binding` to a registered source. An `extension` block ships a renderer-side hook, not a regular page block. A `static` or `interactive` block just takes props. Mismatching the kind → the renderer 422s on publish.

---

## What's exposed in this kit (publish + extension scope)

| Capability | Tool / package | Where in this kit |
|---|---|---|
| Pages (CRUD, publish, duplicate, blocks) | `@spideriq/mcp-publish@1.7.0` | [AGENTS.md](./AGENTS.md), [examples/build-and-deploy.sh](./examples/build-and-deploy.sh) |
| Posts / docs / nav / settings / domains / media | `@spideriq/mcp-publish@1.7.0` | [AGENTS.md](./AGENTS.md) |
| Components (4-class CRUD, propagation, rollback) | `@spideriq/mcp-publish@1.7.0` | [skills/recipes/component-update-and-propagate/](./skills/recipes/component-update-and-propagate/), [skills/recipes/component-rollback/](./skills/recipes/component-rollback/) |
| Templates (Liquid CRUD, themes, deploy) | `@spideriq/mcp-publish@1.7.0` | [skills/templates-engine/](./skills/templates-engine/) |
| Marketplace V2 search + insert | `@spideriq/mcp-publish@1.7.0` (7-tool group: search · list_data_sources · set_component_kind · set_*_agent_meta ×3 · suggest_agent_meta) | [skills/recipes/marketplace-search-and-insert/](./skills/recipes/marketplace-search-and-insert/), [skills/recipes/marketplace-suggest-agent-meta/](./skills/recipes/marketplace-suggest-agent-meta/) |
| Personalization (merge tags, IDAP-fed) | `content_resolve_lead` + Liquid `{{ tag }}` | [MERGE-TAGS.md](./MERGE-TAGS.md), [examples/personalized-landing.sh](./examples/personalized-landing.sh) |
| Directory pages (programmatic SEO) | `directory_*` tool group | [skills/recipes/directory/](./skills/recipes/directory/), [examples/directory-bulk-import.sh](./examples/directory-bulk-import.sh) |
| Booking (SpiderBook, cal.com-backed) | `booking_*` tool group + `{% booking %}` Liquid tag | [skills/booking/](./skills/booking/), [examples/booking-flow.sh](./examples/booking-flow.sh) |
| Media upload + scroll-sequence frames | `media_upload`, `media_extract_frames` | [skills/upload-host-media/](./skills/upload-host-media/), [examples/bulk-media-upload.sh](./examples/bulk-media-upload.sh), [examples/scroll-sequence.sh](./examples/scroll-sequence.sh) |
| Media catalog read (list / search / fetch hosted assets) | `@spideriq/mcp-media@1.0.0` (`catalog_list_assets` · `catalog_get_asset` · `catalog_search_assets`) + CLI `spideriq media list/get/search` | [skills/upload-host-media/](./skills/upload-host-media/), [examples/media-catalog-list.sh](./examples/media-catalog-list.sh) |
| Tilda / Webflow / Lovable migration | `auto_extract_css` + Shadow-DOM wrap | [skills/recipes/tilda-migration/](./skills/recipes/tilda-migration/), [examples/tilda-migrate.sh](./examples/tilda-migrate.sh) |
| Versioned docs (agentdocs) | `agentdocs_*` tool group | [skills/agentdocs/](./skills/agentdocs/) |
| Link-audit (broken internal links pre-deploy) | `content_audit_links` | [skills/recipes/link-audit/](./skills/recipes/link-audit/), [examples/audit-links.sh](./examples/audit-links.sh) |
| IDE-native CMS (pull / native diff / push / deploy) | `SpiderIQ.spideriq-publish@0.1.1` extension | [SURFACES.md](./SURFACES.md), [docs.spideriq.ai/extension](https://docs.spideriq.ai/extension) |

---

## Picking the right surface

Same engine, four rendering surfaces. Pick by ergonomic fit. Full picker in [SURFACES.md](./SURFACES.md).

| You want to… | Use |
|---|---|
| Edit content as files in VSCode/Cursor/Antigravity, with native diff and click-deploy | **IDE extension** — `SpiderIQ.spideriq-publish` |
| Drive the CMS from a chat conversation in Claude Code / Cursor / Windsurf / Antigravity | **MCP** — `@spideriq/mcp-publish` (default; under the ~128-tool injection limit) |
| Run from a headless terminal, CI, cron, or shell scripts | **CLI** — `@spideriq/cli` |
| Plug a recurring multi-step workflow into your agent | **Skills** (Anthropic format in [`skills/`](./skills/)) or **Antigravity KIs** (in `knowledge/antigravity/` once installed) |

The IDE extension and MCP share one engine: the extension spawns `@spideriq/mcp-publish` as a child process. Anything you can do via raw MCP, you can do via the extension UI. There is no second code path.

---

## What's NOT in this kit

Honest limits — what to tell users when they ask:

- **CRM pipelines / contact management** — dashboard surface today; `@spideriq/mcp-leads` covers a slice via API but isn't bundled here.
- **Email outreach / sender warming / verification** — `@spideriq/mcp-mail` covers it via API; not bundled here.
- **Super-admin operations** (cross-tenant moves, brand mutations) — `@spideriq/mcp-admin`, restricted by role.
- **LLM gateway** (multi-provider routing for downstream agents) — `@spideriq/mcp-gate`.
- **Pixel-perfect visual page editor** — the agent-driven shape is deliberate; design fidelity is a function of the components in your library, not a click canvas. A dashboard visual editor exists for human curation but isn't part of this kit.
- **SMS / courses / reputation management** — not on the platform today.

---

## What this is NOT

- **Not a Webflow / Framer alternative** if you want pixel-perfect visual control today. The IDE extension provides a code-shaped surface (native diff over JSON files); the dashboard provides a visual shape for non-developers; neither is a Pencil-design canvas.
- **Not a GoHighLevel replacement** if you need SMS, courses, or reputation management. Those are not on the platform.
- **Not self-hostable.** Runtime stays on our infra; this kit only describes the public API.

---

## Where to next

| If you want to… | Read |
|---|---|
| Pick the right driving surface (CLI vs MCP vs extension vs Skills) | [SURFACES.md](./SURFACES.md) |
| Browse the full tool catalog with payload schemas + error tables | [AGENTS.md](./AGENTS.md) |
| Apply the Phase 11+12 multi-tenant safety contract in Claude Code | [CLAUDE.md](./CLAUDE.md) |
| Make tenant pages LLM-readable for AI search | [GEO.md](./GEO.md) |
| Look up a personalization merge tag | [MERGE-TAGS.md](./MERGE-TAGS.md) |
| Plug in a multi-step workflow | [`skills/recipes/`](./skills/recipes/) |
| Avoid known traps before shipping | [LEARNINGS.md](./LEARNINGS.md) |
