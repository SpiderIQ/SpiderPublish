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
