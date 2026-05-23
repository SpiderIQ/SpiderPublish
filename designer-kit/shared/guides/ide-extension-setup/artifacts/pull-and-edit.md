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
