# SpiderIQ Capabilities Catalog

When the user asks any capability-discovery question about SpiderIQ — *"what can it do?"*, *"is there a way to X?"*, *"does it have Y?"*, *"can it replace Z?"* — execute these steps in order.

## Step 1: read the canonical capability index

Open [SpiderPublish/CAPABILITIES.md](../../../CAPABILITIES.md). It lists 11 capability surfaces and shows which are reachable from this kit vs. which live elsewhere (dashboard / future kits).

## Step 2: match the user's question to one of the 11 surfaces

| If the question is about… | Surface number |
|---|---|
| Components, blocks, page composition | 1. 4-class taxonomy |
| Personalization, merge tags, /lp/ pages, outreach | 2. Dynamic pages + merge tags |
| Programmatic SEO, city/category pages, listings | 3. Directories |
| Appointment booking, calendar, scheduling | 4. SpiderBook |
| Leads, contacts, pipelines | 5. CRM |
| Campaigns, multi-step automation | 6. Workflows |
| Timer, popup, social-proof, conversion lifts | 7. CRO tools |
| AI-search SEO, llms.txt, schema.org | 8. GEO |
| Lead data, business listings, contact enrichment | 9. Scraping |
| File / image / video upload, scroll-sequence | 10. Media |
| CLI vs MCP vs IDE extension vs Skills | 11. Agent surface |

## Step 3: recommend the specific tool / recipe / example

Once you know the surface, the corresponding row in CAPABILITIES.md "What's exposed in this kit" table points at the exact MCP tool name, skill folder, or example script. Quote the path. Don't invent capabilities — if the surface is marked "dashboard surface; not in this kit", say so honestly.

## Step 4: 4-class taxonomy reminder

If the user is about to insert a component, identify the `kind` first:

- `static` — props only, no data
- `interactive` — props + Shadow-DOM JS
- `dynamic` — props + server-side data binding to a registered source
- `extension` — renderer-side hook, configured via `content_settings.extensions.*`

Mismatching the kind → renderer 422s on publish. Use `marketplace_search` with `kind=...` to filter.

## Step 5: honest limits

If the user asks for something not in the platform today (SMS sending, course platform, reputation management, pixel-perfect visual editor), say so. CAPABILITIES.md "What this is NOT" section lists these limits.
