---
name: cli-quick-reference
description: "Run SpiderIQ from the terminal via @spideriq/cli — auth flow, project binding, pages CRUD, marketplace search, deploy, output formats. Same primitives as MCP, no IDE required, supports YAML/MD output for token-efficient agent loops."
---
# @spideriq/cli Quick Reference

When the user wants to run SpiderIQ from a terminal, CI, cron, or shell script, use these commands.

## Install

No install needed — invoke via `npx`:

```bash
npx @spideriq/cli@latest --help
```

Or pin a specific version:

```bash
npx @spideriq/cli@1.7.0 --help
```

## Auth (one-time per machine)

```bash
# Request a PAT via email approval
npx @spideriq/cli auth request \
  --email admin@your-company.com \
  --project "Your Project Name"

# Wait for the admin to click Approve in the email — CLI polls and writes
# the token to ~/.spideriq/credentials.json automatically.

# Verify
npx @spideriq/cli auth whoami
```

For non-interactive contexts (CI), set `SPIDERIQ_TOKEN` in env:

```bash
export SPIDERIQ_TOKEN="cli_xxx:api_yyy:secret_zzz"
npx @spideriq/cli auth whoami
```

## Project binding (per-workspace, mandatory)

```bash
# List projects this token has access to
npx @spideriq/cli use --list

# Bind the current directory to a project (writes ./spideriq.json — commit it)
npx @spideriq/cli use <project_id_or_brand_slug_or_company_name>
```

Without binding, calls fall back to legacy URLs that stop working 2026-05-14.

## Content commands (most common)

```bash
# Pages
npx @spideriq/cli content pages list
npx @spideriq/cli content pages create --slug home --title "Home"
npx @spideriq/cli content pages get <page_id>
npx @spideriq/cli content pages publish <page_id>
npx @spideriq/cli content pages duplicate <page_id> [--slug <new>]

# Posts
npx @spideriq/cli content posts list
npx @spideriq/cli content posts create --slug intro --title "Intro" --tags news,announcement

# Docs (tree)
npx @spideriq/cli content docs tree
npx @spideriq/cli content docs create --path getting-started/install --title "Install"

# Settings
npx @spideriq/cli content settings get
npx @spideriq/cli content settings set --key extensions.feeds.enabled --value true
```

## Marketplace

```bash
npx @spideriq/cli marketplace search --kind static --mood bold --palette dark
npx @spideriq/cli marketplace insert <component_slug> --page <page_id> --position end
```

## Deploy

```bash
npx @spideriq/cli content deploy readiness
npx @spideriq/cli content deploy preview        # returns confirm_token
npx @spideriq/cli content deploy production --confirm-token <cft_...>
npx @spideriq/cli content deploy status
```

Or `--yolo` for non-interactive single-shot deploy (bypasses preview review):

```bash
npx @spideriq/cli content deploy --yolo
```

## Output formats (token-efficient for agent loops)

```bash
npx @spideriq/cli content pages list --format yaml      # ~40-76% smaller than JSON
npx @spideriq/cli content pages list --format md        # human-readable summary
npx @spideriq/cli content pages list --format json      # default
```

## Link audit (pre-deploy)

```bash
npx @spideriq/cli content audit-links
# exits non-zero if any broken internal link found
```

## Common patterns in shell scripts

The kit's `examples/` folder has battle-tested scripts:

- [`examples/check-auth.sh`](../../../examples/check-auth.sh) — auth + binding sanity check
- [`examples/build-and-deploy.sh`](../../../examples/build-and-deploy.sh) — full site build via cURL
- [`examples/audit-links.sh`](../../../examples/audit-links.sh) — broken-link CI gate
- [`examples/personalized-landing.sh`](../../../examples/personalized-landing.sh) — end-to-end /lp/ page

## Don't

- **Paste a PAT into a committed file.** Use `~/.spideriq/credentials.json` (auto-managed) or `SPIDERIQ_TOKEN` env var.
- **Skip `spideriq use` in fresh clones.** Phase 11+12 binding is mandatory; CLI auto-warns if it's missing.
- **Use `--yolo` in production CI.** Run preview first; confirm the token; then production.
