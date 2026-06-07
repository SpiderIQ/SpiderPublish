# SpiderPublish — SURFACES.md

> Same engine, four rendering surfaces. Pick by ergonomic fit. CLI for headless terminals, MCP for chat agents, IDE extension for native diff, Skills for recurring workflows.

This kit is the **content + extension slice**. Other slices (lead-gen, mail, gate, super-admin) ship from separate kits or via the dashboard — see [CAPABILITIES.md](./CAPABILITIES.md#whats-not-in-this-kit).

---

## One engine, four rendering surfaces

```
┌──────────────────────────────────────────────────────────────────┐
│  @spideriq/core@1.6.0  (HTTP client + auth + Phase 11+12 gating) │
└──────────────────────────────────────────────────────────────────┘
       ▲                  ▲                ▲                ▲
       │                  │                │                │
   ┌───┴────┐      ┌──────┴──────┐   ┌─────┴──────┐   ┌────┴──────┐
   │  CLI   │      │     MCP     │   │    IDE     │   │  Skills   │
   │        │      │             │   │ extension  │   │ + KIs     │
   │ npx    │      │ mcp-publish │   │ spawns     │   │ Anthropic │
   │ spideriq│      │ (default)   │   │ mcp-publish│   │ format +  │
   │        │      │ mcp         │   │ as child   │   │ Antigravity│
   │        │      │ (kitchen)   │   │ process    │   │ KIs       │
   └────────┘      └─────────────┘   └────────────┘   └───────────┘
```

The IDE extension is **not parallel to** MCP — it embeds it. On activation the extension spawns `@spideriq/mcp-publish` as a child process (~336 ms cold start) and delegates every backend call to it. Anything you can do via raw MCP, you can do via the extension UI. There is no second code path.

---

## Pick a surface

| You want to… | Use | Install |
|---|---|---|
| Edit content as files in VSCode/Cursor/Antigravity, with native diff and click-deploy | **IDE extension** | `code --install-extension SpiderIQ.spideriq-publish` |
| Drive the CMS from a chat conversation in Claude Code / Cursor / Windsurf / Antigravity | **MCP** (`mcp-publish`) | Drop the kit's [`.mcp.json`](./.mcp.json) into your project root |
| Run from a headless terminal, CI, cron, or shell scripts | **CLI** | `npx @spideriq/cli@latest` (no install needed) |
| Plug a recurring multi-step workflow into your agent | **Skills / KIs** | Anthropic format already in [`skills/`](./skills/) — Antigravity KIs ship in `knowledge/antigravity/` |

---

## CLI — `@spideriq/cli@1.7.0`

The terminal-first surface. Same primitives as MCP, no IDE required.

```bash
# Auth (one-time per machine)
npx @spideriq/cli auth request --email admin@your-company.com --project "Your Project"
npx @spideriq/cli auth whoami

# Bind a workspace to a project (writes ./spideriq.json — commit it)
npx @spideriq/cli use --list
npx @spideriq/cli use <project>

# Content
npx @spideriq/cli content pages list
npx @spideriq/cli content pages create --slug home --title "Home"
npx @spideriq/cli content pages publish <page_id>
npx @spideriq/cli content deploy

# Marketplace
npx @spideriq/cli marketplace search --kind static --mood bold
npx @spideriq/cli marketplace insert <component_slug> --page <page_id>

# Media catalog (read your hosted assets — image / video / doc, across all storage tiers)
npx @spideriq/cli media list --kind image --limit 20
npx @spideriq/cli media search "hero" --tags campaign
npx @spideriq/cli media get <asset_id>

# Output formats (token-efficient for agent loops)
npx @spideriq/cli content pages list --format yaml
npx @spideriq/cli content pages list --format md
```

Full command reference: `npx @spideriq/cli --help` and [docs.spideriq.ai/site-builder/agents](https://docs.spideriq.ai/site-builder/agents).

---

## MCP — `@spideriq/mcp-publish@1.7.0`

The default for site-building. 87 atomic tools, content + extension scope only. Drop-in via the kit's [`.mcp.json`](./.mcp.json).

```jsonc
// .mcp.json (already in this kit — copy to your project root)
{
  "mcpServers": {
    "spideriq": {
      "command": "npx",
      "args": ["-y", "@spideriq/mcp-publish@latest"],
      "env": { "SPIDERIQ_FORMAT": "yaml" }
    }
  }
}
```

**Why `mcp-publish` is the default and not the kitchen-sink `@spideriq/mcp`:**

| Variant | Tools | Scope | When to load |
|---|---|---|---|
| `@spideriq/mcp-publish@1.7.0` | 87 | content + extension only | **Default for site-building.** Under the ~128-tool injection limit some IDE/LLM stacks enforce. Less context burn per turn. |
| `@spideriq/mcp-media@1.0.0` | 3 | media-catalog read only | **Focused.** Just `catalog_list_assets` / `catalog_get_asset` / `catalog_search_assets` over your hosted media. Tiny footprint — load alongside `mcp-publish` when an agent needs to browse the media library without the kitchen sink. |
| `@spideriq/mcp@1.7.0` | 126 | publish + booking + leads + mail + gate + admin | Cross-domain agent that needs every slice in one prompt. Can be dropped silently above ~128 tools by some stacks. |

**Anti-pattern:** never load both `@spideriq/mcp` and `@spideriq/mcp-publish` in the same project. Duplicate tool registration breaks discovery in most IDE/MCP integrations. (`@spideriq/mcp-media` is the exception — it's a 3-tool read-only package with no overlap, safe to add next to `mcp-publish`.)

**Tool catalog:** see [AGENTS.md](./AGENTS.md). Marketplace V2 deep dive: [skills/recipes/marketplace-search-and-insert/](./skills/recipes/marketplace-search-and-insert/).

---

## IDE extension — `SpiderIQ.spideriq-publish@0.1.1`

Edit your CMS like code. A headless CMS that lives in your IDE.

The extension brings every SpiderPublish primitive — pages, posts, components, templates, deploy — into VSCode, Cursor, Antigravity, and any other VSCode-API-compatible editor (Windsurf, VSCodium, Theia, Gitpod). Pulls your tenant's content onto disk, opens it in **VSCode's native diff editor** through virtual URI providers (`spiderpublish-baseline:`, `spiderpublish-remote:`) — not a custom webview — and pushes back with snapshot-bound preview→confirm.

**Three things only this surface does:**

1. **Native VSCode diff for content.** Click any changed entry → real diff editor opens. All editor features work: fold-equal, jump-to-next-change, keyboard navigation.
2. **Subfolder safety.** Walks UP from the active editor's file (not the workspace root) to find `spideriq.json`. Open `clients/acme/pages/home.json` and the extension knows you're in Acme; open `clients/zenith/pages/about.json` and it knows you're in Zenith. Fifty clients in one window — no risk of crossing the streams.
3. **Pre-push link audit with Code Actions.** Phase 0 of every Push scans every page and nav menu for broken internal links. Each broken link gets an inline `vscode.Diagnostic`; the **Accept Proposed Redirect** Quick Fix wires the redirect with one click.

### Install

```bash
# VSCode
code --install-extension SpiderIQ.spideriq-publish

# Cursor / Antigravity / Windsurf (Open VSX)
cursor --install-extension SpiderIQ.spideriq-publish

# From a downloaded .vsix
code --install-extension /path/to/spideriq-publish-0.1.1.vsix
```

Full install guide: [docs.spideriq.ai/extension/install](https://docs.spideriq.ai/extension/install).

### 15 commands at a glance

Every command is registered under the `SpiderPublish:` prefix in the command palette.

| Group | Commands |
|---|---|
| **Auth + binding** | Who Am I? · Select Project… |
| **Read** | Pull Content · Discard Changes |
| **Stage** | Stage / Unstage · Stage All / Unstage All |
| **Write** | Push Content (5-phase) · Push Current File |
| **Deploy** | Deploy Site (5-phase) · Open Last Preview |
| **Audit** | Audit Internal Links · Accept Proposed Redirect (Code Action) |
| **Diagnostic** | Refresh Schemas from Server · Show Diagnostic Info |

### 5-phase Push

```
Phase 0  Pre-push link audit
         └─ broken == 0  → silent pass
         └─ broken > 0   → Review / Push anyway / Cancel modal

Phase 1  Dry-run fan-out (parallel, one per staged record)
         └─ each call returns { preview, confirm_token }

Phase 2  Consolidated review panel
         └─ webview shows every preview side-by-side → Approve all / Cancel

Phase 3  Confirm fan-out (parallel, paired tokens)
         └─ each token consumed exactly once with its paired payload

Phase 3.5  Diagnostics — JSONPath errors decode to inline file:line

Phase 4  Pull-after-push — resync server-normalized fields
```

Snapshot-bound `confirm_token`s pair the preview to the exact payload that requested it. An agent that misbehaves mid-review — generates a new payload, tries to slip it past the confirm — fails at the token check.

### 5-phase Deploy

```
Phase 1  Readiness check  → /content/deploy/readiness → blockers list
Phase 2  Preview          → POST /content/deploy/preview → { preview_url, confirm_token }
Phase 3  Confirm          → POST /content/deploy/production?confirm_token=… → { status: "live", version_id }
Phase 4  Status polling   → /content/deploy/status while status="deploying" (typically 2–5s)
Phase 5  Done             → webview shows live URL + version ID
```

Full command reference: [docs.spideriq.ai/extension/commands](https://docs.spideriq.ai/extension/commands).
Link audit deep dive: [docs.spideriq.ai/extension/link-audit](https://docs.spideriq.ai/extension/link-audit).

---

## Skills — two formats, two install paths

A Skill / Knowledge Item is a curated multi-step workflow the agent can invoke by name. Use them when you find yourself running the same tool sequence repeatedly.

### Anthropic format — `skills/`

5 core skills + 10 recipes already shipped in this kit. Claude Code, Cursor, and Windsurf auto-discover them.

| Type | Folder | Purpose |
|---|---|---|
| Core | [skills/agentdocs/](./skills/agentdocs/) | Versioned documentation projects, multi-page tree, full-text search |
| Core | [skills/booking/](./skills/booking/) | SpiderBook end-to-end appointment booking |
| Core | [skills/content-platform/](./skills/content-platform/) | Multi-tenant pages/posts/docs/nav/components |
| Core | [skills/templates-engine/](./skills/templates-engine/) | Liquid template CRUD + theme management + edge deploy |
| Core | [skills/upload-host-media/](./skills/upload-host-media/) | File/image/video upload to media.cdn.spideriq.ai |
| Recipes | [skills/recipes/](./skills/recipes/) | 10 multi-step workflows (marketplace-search-and-insert, scroll-sequence, tilda-migration, link-audit, directory, …) |

### Antigravity KIs — `knowledge/antigravity/`

Antigravity reads KI summaries at the start of every conversation and auto-loads relevant ones — no `/slash` invocation required. The kit ships 11 KIs covering capability discovery, page creation, marketplace search, deploy, personalized landing, booking, scroll-sequence, GEO readability, MCP package picking, CLI quick reference, and IDE-extension setup.

Install with:

```bash
bash examples/install-antigravity-kis.sh
# Copies knowledge/antigravity/* → ~/.gemini/antigravity/knowledge/
```

The KI format and discovery flow are documented at [Antigravity KI guide](https://docs.spideriq.ai/extension/antigravity-kis) (one source of truth for the format spec).

---

## Cross-surface auth

Every surface uses the same auth model:

- **Token shape:** `Bearer cli_id:api_key:api_secret` (PAT) — request via `npx @spideriq/cli auth request --email <admin>`, approved by an admin via email link
- **Storage:** `~/.spideriq/credentials.json` (global), or `SPIDERIQ_TOKEN` env var
- **Project binding:** `spideriq.json` at the workspace root (Vercel-style convention) — the IDE extension walks UP from the active editor's file to find it; the CLI/MCP walk UP from cwd
- **Phase 11+12 5-lock gating** applies regardless of surface — every dashboard call auto-rewrites to `/api/v1/dashboard/projects/{project_id}/...` and destructive operations require a `confirm_token` from a prior `dry_run=true` preview

**Anti-patterns across all four surfaces:**

| Don't | Why |
|---|---|
| Paste raw PAT into `spideriq.json` | That file is committed. Tokens go in `.env` (kept local) or `~/.spideriq/credentials.json`. |
| Load `@spideriq/mcp` + `@spideriq/mcp-publish` in the same project | Duplicate tool registration; some stacks silently drop one. |
| Skip `spideriq use <project>` | Calls fall back to legacy URLs that stamp `Deprecation: true` and stop working 2026-05-14. |
| Run bulk operations through the IDE extension's tree view | Use the CLI (`spideriq content pages bulk-update`). The extension is optimized for per-file edits with diffs. |
| Reuse a `confirm_token` | Single-use by design — the second call returns 409. Issue a fresh one via `dry_run=true`. |

---

## Where to next

| If you want to… | Read |
|---|---|
| See the full capability index | [CAPABILITIES.md](./CAPABILITIES.md) |
| Look up a specific MCP tool with payload schema | [AGENTS.md](./AGENTS.md) |
| Apply Phase 11+12 multi-tenant safety in Claude Code | [CLAUDE.md](./CLAUDE.md) |
| Make tenant pages LLM-readable for AI search | [GEO.md](./GEO.md) |
| Plug in a multi-step workflow | [`skills/recipes/`](./skills/recipes/) |
| Avoid known traps | [LEARNINGS.md](./LEARNINGS.md) |
