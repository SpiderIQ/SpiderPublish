# Push + Deploy: Shipping Content from the Extension

After [pull-and-edit.md](./pull-and-edit.md), you have local file edits. Push moves those to the SpiderIQ backend; Deploy publishes them to the tenant's Cloudflare edge. Both are gated by Phase 11+12 dry_run/confirm_token — there are no blind writes.

## Push Content (the main flow)

```
SpiderPublish: Push Content
```

Runs the **5-phase pipeline**:

### Phase 0: pre-push link audit

The extension scans every staged page + every navigation menu for broken internal links. If any are found, a modal appears with three outcomes:

- **Review** — focuses the Problems pane; each broken link rendered as a `vscode.Diagnostic` at the offending JSON line. The "Accept Redirect" Code Action proposes a fix.
- **Push anyway** — logs the broken-link list to the output channel and continues. Rare; usually means you're intentionally pushing a page that references something not yet created.
- **Cancel** — abort. No mutation.

### Phase 1: dry-run fan-out

For every staged file, calls the corresponding MCP tool with `dry_run=true`. The server returns a preview envelope with a `confirm_token`, an `expires_at` (default 5 minutes), and a `snapshot_hash` of the exact payload that was previewed.

### Phase 2: consolidated review panel

A single webview shows ALL the previews side-by-side. You see, per file:

- The diff (server's view of "what changes")
- The validation status (✓ valid, ⚠ warnings, ✗ errors with `JSONPath → file:line` decoding)
- The `confirm_token` that will be consumed if you approve

Two buttons: **Approve all** / **Cancel**. There is no per-file approval in v0.1.x — the design is "all or nothing per push" so partial pushes can't leave the tenant in a half-broken state.

### Phase 3: confirm fan-out

For each preview in the batch, calls the same MCP tool again with the paired `confirm_token`. The server validates:

- Token is unconsumed and not expired
- `snapshot_hash` of the new payload matches the snapshot taken at preview time (so an agent can't slip a different payload between preview and confirm)
- Token's bound `(client_id, action, resource_id)` triple matches the URL

If any of those fail, the call returns a structured `ConfirmTokenError` (410 expired / 409 consumed-or-replayed / 403 mismatch) and the entire batch aborts. The tenant ends up with the same state it had before push started.

### Phase 4: pull-after-push

After successful confirms, the extension re-pulls from the server to resync server-normalized fields (e.g. server-generated IDs, `updated_at` timestamps, computed text excerpts). Your local files now reflect the post-push reality. Status bar drops back to `0 changed · N undeployed`.

## Push Current File (tight-loop edits)

```
SpiderPublish: Push Current File
```

Same pipeline but limited to the active editor's file. Skips Phase 0 (no link audit) — use only for single-file iteration where you know the cross-page graph is intact.

## Deploy Site (the second mutation)

Pushing only writes to the SpiderIQ database. Until you deploy, the changes don't reach `https://yoursite.com`. To ship live:

```
SpiderPublish: Deploy Site
```

5-phase: **readiness → preview → confirm → status polling → done.**

- **Readiness check** — verifies the tenant has at least one published page, a primary domain, and the site template applied. Refuses if not (returns a checklist of what's missing).
- **Preview** — calls `content_deploy_site_preview` with `dry_run=true`. Server returns a `preview_url` like `preview-{hash}.sites.spideriq.ai` serving the staging build, plus a `confirm_token`.
- **User reviews preview_url** in their browser. The webview shows it inline + offers an "Open in browser" button.
- **Confirm** — calls `content_deploy_site_production` with the paired token. The server promotes the staging Worker to the tenant's primary domain.
- **Status polling** — every 2 seconds for up to 60 seconds, polls `/deploy/status` until the deploy reports `live` (or `failed`). Webview updates in real time.

**Typical wall-clock: 2–5 seconds end-to-end** for a tenant with 5–20 pages. Most of that is the CF Workers for Platforms script upload, not anything in the extension.

## What "Discard Changes" does

```
SpiderPublish: Discard Changes
```

Reverts the active file to the last-pulled baseline (read from `.spideriq/objects.json`). Equivalent to `git checkout HEAD -- <file>` for tenant content. **Does NOT touch the server** — it just throws away your local edits. Always undoable: re-run Pull and your work is gone, but the live tenant is unaffected.

## Pre-push hook + Code Actions (link audit deep-dive)

When the audit finds a broken internal link, the diagnostic looks like:

```
pages/about.json:42  ⚠ Broken internal link: "/old-pricing" → not found
                       Quick Fix:  Accept proposed redirect → /pricing
```

Hitting the lightbulb (or `Cmd+.`) and selecting **Accept proposed redirect** appends the redirect to `redirects.json`:

```jsonc
{
  "from": "/old-pricing",
  "to":   "/pricing",
  "code": 301
}
```

The Code Action is **idempotent** — running it twice on the same diagnostic is a no-op. It does NOT auto-push the redirect; you still need `SpiderPublish: Push Content` to ship the new redirect alongside whatever else is staged.

## Auditing without pushing

```
SpiderPublish: Audit Internal Links
```

Standalone command — runs the same scan as Phase 0 of Push but without the modal or the push-after. Useful as a pre-deploy sanity check, or when you've made nav changes and want to verify before staging anything.

## Don't

- **Run `Push Current File` for bulk operations.** It skips Phase 0 (link audit). Use `Push Content` for anything multi-file.
- **Edit `redirects.json` to delete entries while files reference the old paths.** That re-introduces broken links the audit will catch on the next push.
- **Cancel a `Deploy Site` between Phase 3 and Phase 4 by force-quitting the IDE.** The server-side promotion still completes; you just lose the status polling. Re-run `Deploy Site` to verify.

## Reference

- [docs.spideriq.ai/extension/commands](https://docs.spideriq.ai/extension/commands) — every command, every option
- [docs.spideriq.ai/extension/link-audit](https://docs.spideriq.ai/extension/link-audit) — link audit details, false-positive handling
- [SpiderPublish CLAUDE.md → Phase 11+12](../../../CLAUDE.md) — the multi-tenant safety contract the push pipeline enforces
- [install.md](./install.md) · [pull-and-edit.md](./pull-and-edit.md) — the other halves of the loop
