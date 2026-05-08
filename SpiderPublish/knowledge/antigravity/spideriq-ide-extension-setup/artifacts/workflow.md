# Install + Set Up the SpiderPublish IDE Extension

When the user wants to install the SpiderPublish extension or asks about IDE-native CMS workflows, execute these steps.

## Step 1: install the extension

```bash
# VSCode (>= 1.85)
code --install-extension SpiderIQ.spideriq-publish

# Cursor (Open VSX)
cursor --install-extension SpiderIQ.spideriq-publish

# Antigravity (Open VSX)
antigravity --install-extension SpiderIQ.spideriq-publish

# Windsurf / VSCodium / Theia / Gitpod — same Open VSX pattern
```

Or in any of the above: `Cmd+Shift+X` → search "SpiderPublish" → Install.

After install, look for:
- A **SpiderPublish** icon in the Activity Bar (left edge)
- A `📁 not signed in` entry in the status bar (bottom-right)

## Step 2: get an access token

If the user doesn't already have a PAT:

```bash
npx @spideriq/cli auth request \
  --email admin@your-company.com \
  --project "Your Project Name"
```

Wait for the admin to click Approve in the email. The CLI writes the token to `~/.spideriq/credentials.json`.

The extension picks up that file automatically — no copy-paste.

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

If the prompt asks to paste a token, the credentials file isn't readable — check `~/.spideriq/credentials.json` exists and is readable.

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

**Commit this file.** It's the per-folder tenant binding — anyone else who clones the repo auto-binds to the same project.

## Step 5: first pull

```
SpiderPublish: Pull Content
```

Fans out parallel per-type GETs and writes the tenant's content as JSON files:

```
your-project/
  ├── spideriq.json
  ├── pages/        ← .json files per page
  ├── posts/
  ├── components/
  ├── templates/
  ├── redirects.json
  └── .spideriq/    ← gitignore'd registry (the .git/index analogue)
```

The Activity Bar's SpiderPublish view now shows tree-grouped content.

## Step 6: edit + push workflow

Pick a file, edit, save:

1. Status bar updates: `📁 project · N changed · M undeployed`
2. Click the file in the Changes view → **native VSCode diff editor** opens (left = last-pulled baseline, right = current)
3. `SpiderPublish: Stage` — git-style staging
4. `SpiderPublish: Push Content` — runs the 5-phase pipeline:
   - Phase 0: pre-push link audit (broken links → modal: Review / Push anyway / Cancel)
   - Phase 1: dry-run fan-out
   - Phase 2: consolidated review panel — Approve all / Cancel
   - Phase 3: confirm fan-out (paired tokens)
   - Phase 4: pull-after-push to resync server-normalized fields

## Step 7: deploy from the palette

```
SpiderPublish: Deploy Site
```

5-phase: readiness → preview → confirm → status polling → done. Webview shows the live URL.

## Subfolder safety (multi-tenant agencies)

The extension walks UP from the **active editor's file** (not the workspace root) looking for `spideriq.json`. So an agency can keep fifty clients open:

```
~/agency-clients/
  ├── acme-corp/        ← spideriq.json bound to Acme
  │   └── pages/home.json
  └── zenith/           ← spideriq.json bound to Zenith
      └── pages/about.json
```

Open `acme-corp/pages/home.json` and the extension knows you're in Acme. Open `zenith/pages/about.json` and it knows you're in Zenith. **No risk of crossing the streams.**

## Troubleshooting

```
SpiderPublish: Show Diagnostic Info
```

Dumps activation state, credentials.json layout, MCP subprocess status, and the latest `auth_whoami` round-trip into the output channel. Token values are redacted. Paste this into support reports.

```
SpiderPublish: Refresh Schemas from Server
```

Force-refresh the cached `/content/help`, `/content/playbook`, `/content/variables` (default cache: 24 hours). Use after backend schema changes.

## Don't

- **Paste a PAT into `spideriq.json`.** That file is committed; tokens go in credentials.json (auto-managed) or env vars.
- **Edit `.spideriq/objects.json`.** That's the registry — the local .git/index analogue. Edited by hand, the diff view breaks.
- **Use `Push Current File` for bulk operations.** It skips Phase 0 (link audit). Use `Push Content` for anything multi-file.
- **Mix the extension with raw MCP in the same session for the same project.** Both will try to mutate; the second one's `confirm_token` might hit a snapshot mismatch.

## Reference

- [docs.spideriq.ai/extension](https://docs.spideriq.ai/extension) — overview
- [docs.spideriq.ai/extension/install](https://docs.spideriq.ai/extension/install) — full install guide
- [docs.spideriq.ai/extension/commands](https://docs.spideriq.ai/extension/commands) — every command reference
- [docs.spideriq.ai/extension/troubleshooting](https://docs.spideriq.ai/extension/troubleshooting) — common issues
