# SpiderPublish

The starter kit for building on **SpiderPublish** — SpiderIQ's multi-tenant
headless CMS + booking runtime.

## What's inside

### [`designer-kit/`](./designer-kit)

Greenfield starter for designers and developers who build SpiderPublish
templates full-time. Includes `AGENTS.md`, `CLAUDE.md`, `SETUP-PROMPT.md`,
runtime configs for Antigravity / Claude Code / Cursor / Codex, and shared
recipes / components / templates ready to extend.

```bash
npx degit SpiderIQ/SpiderPublish/designer-kit my-templates-project
cd my-templates-project
# follow designer-kit/SETUP-PROMPT.md
```

## Agent skills (different door)

Agents working on a customer's existing project don't pull this kit — they
install the SpiderIQ skill suite into their runtime instead:

```bash
npx skills add SpiderIQ/skills
```

Skills install into your agent's runtime (`~/.claude/skills/`, etc.); they
never touch your project's `CLAUDE.md` / `AGENTS.md` / `.cursorrules`.

## Links

- **Platform:** [spideriq.ai](https://spideriq.ai)
- **Site-builder docs:** [docs.spideriq.ai/site-builder](https://docs.spideriq.ai/site-builder/overview)
- **API health:** [spideriq.ai/api/v1/system/health](https://spideriq.ai/api/v1/system/health)

## Getting access

```bash
npx @spideriq/cli auth request --email admin@company.com --project "My Project" --registry https://npm.spideriq.ai
```

Or email [admin@spideriq.ai](mailto:admin@spideriq.ai).
