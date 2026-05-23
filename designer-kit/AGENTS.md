# SpiderPublish — AGENTS.md (deprecation stub, retiring ~2026-06-09)

> **Moved.** This file is a one-release-cycle redirect. The canonical AGENTS.md now lives at:
>
> - **[runtimes/antigravity/AGENTS.md](./runtimes/antigravity/AGENTS.md)** — full tool catalog with payload schemas (Antigravity)
> - **[runtimes/cursor/AGENTS.md](./runtimes/cursor/AGENTS.md)** — same catalog, Cursor-friendly framing
>
> If you bootstrapped via `npx degit SpiderIQ/SpiderPublish/designer-kit/runtimes/<runtime> .`, you already have it as `AGENTS.md` in your project root.

## Why the move?

Pre-1.0 starter kits shipped one bundle for every runtime. Each runtime's agent picked up the wrong half (Antigravity reading recipe SKILL.md without metadata, Claude Code missing KI workflows).

The kit is now organized as:

- **[shared/](./shared/)** — canonical content (`content/`, `recipes/`, `core-skills/`, `guides/`, `components/`, `examples/`, `templates/`)
- **[runtimes/](./runtimes/)** — per-runtime emitted trees
- **[scripts/build.ts](./scripts/build.ts)** — regenerates `runtimes/` from `shared/`
- **[manifest.json](./manifest.json)** — runtime + skill registry
- **[SETUP-PROMPT.md](./SETUP-PROMPT.md)** — paste prompt that branches by runtime

## Pointers

- Bootstrapping a fresh project: paste [SETUP-PROMPT.md](./SETUP-PROMPT.md) into your agent
- Running Antigravity: read [runtimes/antigravity/AGENTS.md](./runtimes/antigravity/AGENTS.md) and run [runtimes/antigravity/install-knowledge-items.sh](./runtimes/antigravity/install-knowledge-items.sh)
- Running Cursor: read [runtimes/cursor/AGENTS.md](./runtimes/cursor/AGENTS.md); rules auto-load from `.cursor/rules/`
- Repo overview: [README.md](./README.md)

This stub will be removed approximately **2026-06-09**.
