# SpiderPublish — Universal Setup Prompt

> Paste this into your IDE's chat / agent panel. The agent self-detects which runtime it is, then runs only the matching block. No human branching needed.

---

You are about to set up the SpiderPublish Starter Kit in this project. Identify yourself by which environment you're running in, then execute **only the matching block**:

## If you are Claude Code

```bash
npx degit martinshein/SpideriQ-ai/SpiderPublish/runtimes/claude-code .
```

Then read `CLAUDE.md` from the project root. Skills auto-load from `.claude/skills/` based on user intent. The bundled `.mcp.json` configures `@spideriq/mcp-publish` (87 tools, atomic publish slice). Continue with:

1. `npx @spideriq/cli auth request --email <admin-email>` — request a PAT (admin must approve)
2. `npx @spideriq/cli use --list` then `npx @spideriq/cli use <project>` — bind this directory (writes `./spideriq.json`, **commit it**)
3. Restart Claude Code so it picks up the new `.mcp.json`

## If you are Google Antigravity

```bash
npx degit martinshein/SpideriQ-ai/SpiderPublish/runtimes/antigravity ./.spideriq-ref
bash ./.spideriq-ref/install-knowledge-items.sh
cp ./.spideriq-ref/.mcp.json ./.mcp.json   # if your project doesn't already have one
```

The installer copies all 20 Knowledge Items to `~/.gemini/antigravity/knowledge/`. Antigravity auto-loads relevant KIs based on user intent — no `/slash` invocation needed. Then read `./.spideriq-ref/AGENTS.md` for the tool catalog.

Continue with the same auth + bind steps as above. Restart Antigravity so it picks up the new KIs and `.mcp.json`.

## If you are Cursor

```bash
npx degit martinshein/SpideriQ-ai/SpiderPublish/runtimes/cursor .
```

Cursor auto-loads `.cursor/rules/_index.mdc` (root rule) and per-skill rules under `.cursor/rules/*.mdc` based on description match. The bundled `.mcp.json` registers `@spideriq/mcp-publish`. Read `AGENTS.md` for the tool catalog.

Continue with the auth + bind steps. Restart Cursor so it picks up the new MCP config and rules.

## If you are Claude Desktop

Claude Desktop has no auto-bootstrap (no MCP discovery from a folder, no skill loading). Use the manual setup:

```bash
npx degit martinshein/SpideriQ-ai/SpiderPublish/runtimes/claude-desktop ./.spideriq-ref
```

Then read `./.spideriq-ref/README.md` — it walks you through editing `claude_desktop_config.json`, registering `@spideriq/mcp-publish`, and the manual prompt-pasting workflow (no skill auto-loading on Claude Desktop).

## If you are Windsurf, VS Code with Claude Code extension, or any other MCP-compatible IDE

Use the **Claude Code** branch above. Windsurf and VSCode-with-Claude-Code share the same `.claude/skills/` + `.mcp.json` shape, and the SpiderPublish IDE extension (SpiderIQ.spideriq-publish on [Open VSX](https://open-vsx.org/extension/SpiderIQ/spideriq-publish) and [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=SpiderIQ.spideriq-publish)) gives you native diff + push UI on top.

## If you are unsure which runtime you are

Default to the **Claude Code** branch. The runtime trees are independent — you can install one and switch later by deleting the bootstrapped files and running a different branch.

---

After bootstrapping, verify with:

```bash
npx @spideriq/cli auth whoami
# → should print your client_id, brand, and bound project
```

If `whoami` reports "not authenticated" or "no project bound," loop back through the auth + bind steps. Most issues at this stage are missing `./spideriq.json` (Phase 11+12 Lock 3).

## Why per-runtime trees?

Every runtime sees a different shape:

- Claude Code reads `.claude/skills/<id>/SKILL.md` with YAML frontmatter
- Antigravity reads `~/.gemini/antigravity/knowledge/<NN>-spideriq-<id>/{metadata.json, artifacts/}`
- Cursor reads `.cursor/rules/<id>.mdc` with description-matched auto-loading
- Claude Desktop reads nothing automatically — manual paste only

A single mixed bundle (the pre-1.0 layout) leaked the wrong half into each runtime — Antigravity tried to read SKILL.md without YAML metadata, Claude Code missed the KI workflows, etc. The per-runtime trees ship the format each environment actually expects.

The canonical content lives in [`shared/`](./shared/) and is regenerated into each runtime via `npm run build`. Edit `shared/`, regenerate, commit; never edit `runtimes/` directly.
