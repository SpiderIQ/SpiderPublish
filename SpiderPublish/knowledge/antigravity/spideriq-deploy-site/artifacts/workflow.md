# Deploy a SpiderIQ Tenant Site

When the user says deploy / publish / go live / ship / push to production, execute these five phases.

## Phase 1: readiness check

```
content_deploy_readiness
```

Returns a list of blockers. The deploy will reject with 400 if any of these are missing:

- Site settings with `site_name`
- At least 1 verified domain
- At least 1 template (theme applied)
- At least 1 published page

Fix every blocker before proceeding. Common fixes:

- No site_name → `content_update_settings({ site_name: "..." })`
- No verified domain → `content_add_domain({ domain: "..." })` then verify DNS
- No template → `template_apply_theme({ theme: "default" })`
- No published page → `content_publish_page({ page_id: "..." })`

## Phase 2: preview

```
content_deploy_site_preview
// returns { preview_url, confirm_token, expires_at, snapshot_hash }
```

Open `preview_url` in a browser. The URL pattern is `preview-{hash}.sites.spideriq.ai` — a staging snapshot exposed via CF-for-SaaS.

If anything looks wrong, fix the underlying content/settings and re-run `content_deploy_site_preview`. The token is snapshot-bound — the previous one is invalidated by the new content.

## Phase 3: confirm

```
content_deploy_site_production({ confirm_token: "cft_..." })
// returns { status: "deploying", version_id }
```

Single-use token. The system pairs the token to the exact preview snapshot — an in-flight content edit invalidates it (you'll get 403 TokenClientMismatch).

## Phase 4: poll status

```
content_deploy_status
// while status === "deploying", poll every 2 seconds
// stops when status === "live" or status === "failed"
```

Typical end-to-end: 2–5 seconds.

## Phase 5: report

If status="live":
- Print the live URL (the tenant's primary domain) and the version_id.

If status="failed":
- The response includes a JSONPath-decoded error pointing at the failing field/block. Fix and retry from Phase 2.

## Phase 11+12 error reference

| Status | Cause | Fix |
|---|---|---|
| `403 TokenClientMismatch` | Token was for a different project | Wrong directory — check `spideriq.json` |
| `403 TokenActionMismatch` | Token was for a different action | Don't reuse tokens across operations |
| `409 TokenConsumed` | Single-use token already used | Issue a fresh one via `content_deploy_site_preview` |
| `410 TokenExpired` | Past `expires_at` (7 days) | Issue a fresh one |

## Don't

- **Skip Phase 1.** Deploy will reject; you'll waste a token.
- **Hand-craft the deploy URL.** Always go through `content_deploy_site_preview` to get the snapshot-bound token.
- **Reuse a confirm_token across two deploys.** Each deploy consumes its own token.
