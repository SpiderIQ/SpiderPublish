---
name: ide-extension-setup
description: "Install + bind the SpiderPublish IDE extension (SpiderIQ.spideriq-publish) in VSCode, Cursor, Antigravity, Windsurf. Three artifacts: install.md (extension + auth + project binding), pull-and-edit.md (working tenant content as files + native diff + stage), push-and-deploy.md (5-phase push pipeline + Deploy Site + link audit). The extension wraps @spideriq/mcp-publish (87 tools) as a child process — same primitives, click-driven instead of typed."
---
<!-- artifact: install.md -->

# Install + Sign In: SpiderPublish IDE Extension

When the user wants to install the SpiderPublish extension, asks about IDE-native CMS workflows, or is starting a fresh project where multi-section editing is on the table, run these steps.

The extension is `SpiderIQ.spideriq-publish` (publisher: SpiderIQ, name: spideriq-publish). It's available on:

- **VS Code Marketplace** — for VS Code 1.85+
- **Open VSX** — for Cursor, Antigravity, Windsurf, VSCodium, Theia, Gitpod, and any VSCode-API-compatible IDE

You do NOT need to install both. Each IDE pulls from one registry.

## Step 1: install the extension

```bash
# VSCode (>= 1.85)
code --install-extension SpiderIQ.spideriq-publish

# Cursor (Open VSX)
cursor --install-extension SpiderIQ.spideriq-publish

# Antigravity (Open VSX)
antigravity --install-extension SpiderIQ.spideriq-publish

# Windsurf / VSCodium / Theia / Gitpod — same Open VSX pattern
windsurf --install-extension SpiderIQ.spideriq-publish
```

Or in any of the above: `Cmd+Shift+X` → search "SpiderPublish" → Install.

After install, look for:

- A **SpiderPublish** icon in the Activity Bar (left edge)
- A `📁 not signed in` entry in the status bar (bottom-right)

If neither shows up, the install didn't activate cleanly. Reload the IDE window (`Cmd+Shift+P` → `Developer: Reload Window`) and check again.

## Step 2: get an access token

The extension uses the **same** auth flow as `@spideriq/cli` and `@spideriq/mcp-publish`. If the user already has working credentials at `~/.spideriq/credentials.json` (e.g. they ran `npx @spideriq/cli auth request` earlier in this session or in another project), the extension picks those up automatically — skip to Step 3.

If they don't:

```bash
npx --registry=https://npm.spideriq.ai @spideriq/cli auth request \
  --email admin@your-company.com \
  --project "Your Project Name"
```

The CLI sends an approval email to the admin. The admin clicks Approve. The CLI writes the token to `~/.spideriq/credentials.json`. The extension reads from that file — no copy-paste, no environment variable.

If the admin approval times out (default 20 min), re-run the same command. The original `request_id` stays valid for 24 hours.

## Step 3: sign in (verify auth)

In the IDE, open the command palette (`Cmd+Shift+P` / `Ctrl+Shift+P`):

```
SpiderPublish: Who Am I?
```

Output should show:

```
✓ Signed in as agent_xxxxxxxxxxxxxxxx
  email:    admin@your-company.com
  brand:    Your Brand
```

If the prompt asks to paste a token, the credentials file isn't readable — verify `~/.spideriq/credentials.json` exists and has user-readable permissions.

## Step 4: bind the workspace to a project

```
SpiderPublish: Select Project…
```

Pick from the list. The extension writes `spideriq.json` to the workspace root:

```json
{
  "project_id": "cli_xxxxxxxxxxxxxxxx",
  "project_name": "Your Project",
  "api_url": "https://spideriq.ai",
  "created_at": "2026-05-08T..."
}
```

**Commit this file.** It's the per-folder tenant binding — anyone else who clones the repo (or any AI agent that opens the workspace later) auto-binds to the same project. This is Phase 11+12 Lock 3 — destructive operations refuse to run when the URL `project_id` doesn't match the binding.

## Subfolder safety (multi-tenant agencies)

The extension walks UP from the **active editor's file** (not the workspace root) looking for `spideriq.json`. So an agency can keep fifty clients open in one window:

```
~/agency-clients/
  ├── acme-corp/        ← spideriq.json bound to Acme
  │   └── pages/home.json
  └── zenith/           ← spideriq.json bound to Zenith
      └── pages/about.json
```

Open `acme-corp/pages/home.json` and the extension knows you're in Acme. Open `zenith/pages/about.json` and it knows you're in Zenith. **No risk of crossing the streams.**

## When to install the extension vs. stay MCP-only

| Scenario | Extension | MCP-only |
|---|---|---|
| Single-section page edit through chat | Optional | ✓ Sufficient |
| Multi-section page edit, want to review deltas before pushing | ✓ Native diff catches misplaced fields | Possible but error-prone |
| Long-running session with many small edits | ✓ Status bar tracks dirty + undeployed | Possible but no visible state |
| Agency loop over many tenants in one window | ✓ Per-folder `spideriq.json` walk | CLI works, no UI affordance |
| Headless CI / scripts | — | ✓ Use the CLI |
| Claude Desktop chat (no VSCode-API IDE) | Not available | ✓ MCP-only |
| Terminal-only environments (SSH, containers) | Not available | ✓ Use CLI / MCP |

After install, run `SpiderPublish: Pull Content` to land tenant content on disk — see [pull-and-edit.md](./pull-and-edit.md) for the daily-use loop.

## Reference

- [docs.spideriq.ai/extension](https://docs.spideriq.ai/extension) — overview
- [docs.spideriq.ai/extension/install](https://docs.spideriq.ai/extension/install) — full install guide
- [Open VSX listing](https://open-vsx.org/extension/SpiderIQ/spideriq-publish) — for Cursor / Antigravity / Windsurf
- [VS Code Marketplace listing](https://marketplace.visualstudio.com/items?itemName=SpiderIQ.spideriq-publish) — for VS Code


---

<!-- artifact: pull-and-edit.md -->

# Pull + Edit: Working Tenant Content as Files

After install + sign-in (see [install.md](./install.md)), the extension is dormant until you run **Pull Content**. Pull lands tenant content on disk; you edit those files like normal source; the extension renders deltas natively. Push happens via [push-and-deploy.md](./push-and-deploy.md).

## First pull

```
SpiderPublish: Pull Content
```

Fans out parallel per-type GETs and writes the tenant's content as JSON files:

```
your-project/
  ├── spideriq.json
  ├── pages/        ← .json files per page (slug = filename)
  ├── posts/
  ├── components/
  ├── templates/
  ├── redirects.json
  └── .spideriq/    ← gitignore'd registry (the .git/index analogue)
```

The Activity Bar's SpiderPublish view now shows tree-grouped content. The status bar updates to:

```
📁 acme-corp · 0 changed · 0 undeployed
```

## Pull semantics — three-way merge, not blind overwrite

If you have local edits when you re-run Pull, the extension does a **three-way merge** between:

- the last-pulled baseline (in `.spideriq/objects.json`),
- the current server state (just fetched),
- and your local working tree.

Files you haven't touched get overwritten with the server version (so you stay current). Files you HAVE touched get a merge-conflict markup if the server moved underneath you. The native VSCode merge editor opens for resolution.

This means **Pull is safe to re-run mid-session** — you won't lose unsaved work.

## Editing content as files

Pages, posts, docs, components, and templates each have a canonical JSON shape. When you open one, VSCode's JSON IntelliSense kicks in (the extension registers JSON schemas for every type at activation).

```jsonc
// pages/home.json
{
  "slug": "home",
  "title": "Acme Corp",
  "template": "default",
  "blocks": [
    { "type": "hero", "data": { "headline": "Welcome", "...": "..." } },
    { "type": "component", "component_slug": "pricing-3tier", "props": { "...": "..." } }
  ],
  "seo_title": "...",
  "seo_description": "..."
}
```

Edit the JSON directly. Save. The extension watches the file and:

1. Marks it as `changed` in the status bar
2. Surfaces it in the Activity Bar's Changes view
3. Computes its position in the dependency graph (e.g. a component edit may flag pages that reference it as `affected`)

## Native VSCode diff (the killer feature)

Click any changed file in the Changes view → **native VSCode diff editor** opens:

- **Left pane** = the last-pulled baseline (read from `.spideriq/objects.json`)
- **Right pane** = your current working tree
- **Inline gutter** = jump-to-next-change, accept-line, reject-line — same affordances as `git diff`

This is **not** a webview. The extension uses VSCode's virtual URI providers (`spiderpublish-baseline:`, `spiderpublish-remote:`) so the actual built-in diff editor renders.

The same affordance works for "diff against live" — right-click a file → `SpiderPublish: Diff Against Live` shows your local vs. the current server state without overwriting anything.

## Stage / Unstage (git-style)

Inline tree actions on the Changes view:

- `SpiderPublish: Stage` — mark file as ready to push
- `SpiderPublish: Unstage` — pull it back out of the staged set
- `SpiderPublish: Stage All`, `SpiderPublish: Unstage All` — bulk

Staging matters for push-ergonomics: `SpiderPublish: Push Content` only sends staged files. So you can have 12 dirty files but push 3 in one batch and 9 in another, with separate review cycles.

## Refresh schemas after backend changes

```
SpiderPublish: Refresh Schemas from Server
```

Force-refresh the cached `/content/help`, `/content/playbook`, `/content/variables` (default cache: 24 hours). Use after backend schema changes or when JSON IntelliSense feels stale.

## Don't

- **Edit `.spideriq/objects.json`.** That's the registry — the local `.git/index` analogue. Edited by hand, the diff view breaks.
- **Mix the extension with raw MCP in the same session for the same project.** Both will try to mutate; the second one's `confirm_token` might hit a snapshot mismatch.
- **Delete `spideriq.json` after a Pull.** It's the binding to the tenant; without it the extension can't know which project the files belong to. Re-run `SpiderPublish: Select Project…` if you really need to rebind.

## Troubleshooting

```
SpiderPublish: Show Diagnostic Info
```

Dumps activation state, credentials.json layout, MCP subprocess status, and the latest `auth_whoami` round-trip into the output channel. Token values are redacted. Paste this into support reports.

If Pull fails:

- **401 Unauthorized** — credentials expired. Re-run `npx @spideriq/cli auth request --email <admin>` and try again.
- **403 Forbidden** — `spideriq.json` binds to a project the current PAT doesn't have access to. Run `SpiderPublish: Select Project…` and pick one your PAT can reach.
- **Empty tree** — the tenant genuinely has no content yet (fresh tenant). Create a page in the dashboard or via MCP, then re-Pull.

## Reference

- [docs.spideriq.ai/extension/commands](https://docs.spideriq.ai/extension/commands) — every command reference
- [docs.spideriq.ai/extension/troubleshooting](https://docs.spideriq.ai/extension/troubleshooting) — common issues
- [push-and-deploy.md](./push-and-deploy.md) — the other half of the daily loop


---

<!-- artifact: push-and-deploy.md -->

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
