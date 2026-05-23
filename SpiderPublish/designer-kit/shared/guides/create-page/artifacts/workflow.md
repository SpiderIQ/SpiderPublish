# Create a SpiderIQ Tenant Page

When the user asks to create, add, or spin up a new page, execute these steps exactly in this order.

## Step 1: read the agent help reference

Call `template_get_help` first. Returns a YAML reference with the canonical task index, block schemas, theme palette, session-binding contract, and deploy workflow. Treat this as ground truth — every block and prop in your `content_create_page` call must match it.

## Step 2: confirm session binding

Run `auth_whoami`. The response must include a `client_id` matching the `project_id` in `./spideriq.json`. If not, run `npx @spideriq/cli use <project>` first — every dashboard call from here on auto-rewrites to the project-scoped URL.

## Step 3: build the page payload

Use the canonical block shape from [components/block-component.json](../../../components/block-component.json) and [components/block-rich-text.json](../../../components/block-rich-text.json). Common block types: `hero`, `features_grid`, `cta_section`, `testimonials`, `pricing_table`, `faq`, `stats_bar`, `rich_text`, `image`, `video_embed`, `code_example`, `logo_cloud`, `comparison_table`, `spacer`, `component`.

Anti-pattern (rejected with 422 since 2026-04-24): `{type: "component", data: {slug: "..."}}`. The slug goes at the block top level: `{type: "component", component_slug: "...", data_binding?: {...}, layout?: "..."}`.

## Step 4: call content_create_page

```
content_create_page({
  slug: "pricing",
  title: "Pricing",
  template: "default",
  blocks: [...]
})
```

Slug `home` is reserved for the homepage. Other slugs become `/about`, `/pricing`, etc.

## Step 5: publish (gated)

```
content_publish_page({ page_id: "...", dry_run: true })
// returns { preview, confirm_token, expires_at }
content_publish_page({ page_id: "...", confirm_token: "cft_..." })
```

The first call returns a preview envelope; the second consumes the token and applies. Tokens are single-use, snapshot-bound, expire after 7 days.

## Step 6: apply theme (if not already applied)

```
template_apply_theme({ theme: "default", dry_run: true })
template_apply_theme({ theme: "default", confirm_token: "cft_..." })
```

## Step 7: deploy

```
content_deploy_readiness         // check blockers
content_deploy_site_preview      // returns { preview_url, confirm_token }
content_deploy_site_production({ confirm_token: "cft_..." })
content_deploy_status            // poll until status="live"
```

Typically 2–5 seconds end to end.

## Common mistakes to avoid

- Forget `spideriq use` — calls fall back to legacy URLs that stop working 2026-05-14.
- Reuse a `confirm_token` — single-use; second call returns 409.
- Set `primary_color` expecting a dark background — that's the ACCENT only. Use `surface_color` + `body_text_color` + `heading_color` for the page palette.
- Skip step 2's binding check — wrong-tenant deploys are silently impossible (Phase 11+12 Lock 1) but the error is opaque if you don't know binding state.
