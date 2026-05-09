# SpiderPublish — CLAUDE.md (deprecation stub, retiring ~2026-06-09)

> **Moved.** This file is a one-release-cycle redirect. The canonical Claude Code context now lives at:
>
> **[runtimes/claude-code/CLAUDE.md](./runtimes/claude-code/CLAUDE.md)**
>
> If you bootstrapped via `npx degit martinshein/SpideriQ-ai/SpiderPublish/runtimes/claude-code .`, you already have it as `CLAUDE.md` in your project root.

## Why the move?

Pre-1.0 starter kits shipped one bundle for every runtime — Claude Code's `CLAUDE.md`, Antigravity's `AGENTS.md`, recipe / Knowledge Item content all in the same folder. Each runtime's agent picked up the wrong half (e.g. Antigravity reading SKILL.md without its YAML metadata, Claude Code missing the KI workflows).

The kit is now organized as:

- **[shared/](./shared/)** — canonical source of truth for content, recipes, components, examples
- **[runtimes/](./runtimes/)** — per-runtime emitted trees: `claude-code/`, `antigravity/`, `cursor/`, `claude-desktop/`
- **[scripts/build.ts](./scripts/build.ts)** — regenerates `runtimes/` from `shared/` (run with `npm run build`)
- **[manifest.json](./manifest.json)** — runtime + skill registry consumed by the build script
- **[SETUP-PROMPT.md](./SETUP-PROMPT.md)** — paste prompt that branches by runtime

Each runtime's tree is `degit`-friendly (one-liner setup) and emits in the format the agent in that runtime actually expects.

## Pointers

- Building from scratch in a fresh project: paste [SETUP-PROMPT.md](./SETUP-PROMPT.md) into your agent
- Running Claude Code: read [runtimes/claude-code/CLAUDE.md](./runtimes/claude-code/CLAUDE.md)
- Editing the canonical content: edit `shared/` and run `npm run build`
- Repo overview: [README.md](./README.md)

This stub will be removed approximately **2026-06-09** (~30 days post-restructure). After that, only the per-runtime trees and `shared/` remain.
