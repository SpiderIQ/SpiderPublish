---
name: pick-mcp-package
description: "Decide which @spideriq/mcp-* npm package to install. Use whenever the user asks '@spideriq/mcp vs @spideriq/mcp-publish', 'kitchen-sink vs atomic MCP', 'why is the agent dropping tools?'. Almost always the answer is @spideriq/mcp-publish; the kitchen-sink @spideriq/mcp is only for cross-domain agents."
---
# Pick the Right @spideriq/mcp-* Package

When the user asks which MCP package to install, or reports tool-injection problems, walk this decision tree.

## The default answer

**`@spideriq/mcp-publish@1.7.0`** — 87 tools, content + extension scope only. Use this unless you have a specific reason not to.

The kit's [`.mcp.json`](../../../.mcp.json) already pins this. If the user copied that file into their project, they're done.

## When to use the kitchen-sink instead

`@spideriq/mcp@1.7.0` (126 tools) bundles content + extension + booking + leads + mail + gate + admin. Pick it ONLY if the user's session genuinely needs every slice in one prompt — for example, an agent that simultaneously:

- Submits a SpiderMaps job (lead-gen)
- Triggers SpiderVerify on the results (mail)
- Routes generated copy through SpiderGate (gate)
- Builds a landing page from the verified leads (publish)
- Schedules outbound campaign in WindMill (workflows)

That kind of cross-domain agent needs the kitchen sink. A focused site-builder agent doesn't.

## Why mcp-publish is preferred when possible

1. **~128-tool injection limit.** Some IDE/LLM stacks (notably some older Cursor builds, some Antigravity configurations) silently drop tool injections above ~128. The kitchen-sink at 126 tools is right at the edge — adding any other MCP server pushes over.
2. **Context burn per turn.** Every tool schema is sent to the LLM on every turn. 87 tools × ~150 tokens/schema ≈ 13K tokens/turn. 126 tools ≈ 19K tokens/turn. Over a long session, that's tens of thousands of tokens of overhead that doesn't help the task.
3. **Scope clarity for the agent.** A focused tool surface produces focused agent behavior. An agent with admin tools available will occasionally try them when the user didn't ask.

## When the user reports "tools are missing" or "the agent doesn't know about X"

Run this checklist:

1. Confirm `.mcp.json` is at the project root and references the right package
2. Restart the IDE / Claude Code session — MCP servers load on startup
3. Run `auth_whoami` to confirm the MCP server is reachable
4. If `whoami` works but a specific tool is "missing": check the package — `mcp-publish` doesn't expose `lead_*`, `mail_*`, `gate_*`, or `admin_*` tools. Switch to `mcp` or load a separate package only if needed.

## Anti-patterns

- **Loading both `@spideriq/mcp` and `@spideriq/mcp-publish` in the same project.** Duplicate tool registration breaks discovery in most IDE/MCP integrations. The agent picks one randomly per turn.
- **Pinning `latest` without version-locking.** The kit pins `@spideriq/mcp-publish@latest` via `npx` in `.mcp.json` — that's intentional for the public kit (always-fresh). For production agency setups, pin a specific version (e.g. `@spideriq/mcp-publish@1.7.0`).
- **Adding `@spideriq/mcp-mail` / `mcp-leads` / etc. just because they exist.** Each added MCP server stacks tool count and context burn. Only add what the agent actually needs.

## Reference

Full picker with package matrix at [SURFACES.md](../../../SURFACES.md#mcp--spideriqmcp-publish170).
