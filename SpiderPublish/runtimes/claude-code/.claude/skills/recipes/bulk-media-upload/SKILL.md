---
name: bulk-media-upload
description: "Upload a local directory of files directly via multipart POST. Kills the pinggy/catbox/serveo tunnel workaround. Use whenever you need to push frame sequences, image sets, or asset bundles to SpiderMedia from your local disk."
---
# recipes/bulk-media-upload

Upload a local file or directory to SpiderMedia — **one tool call**. Scroll-sequence folders auto-optimize on the way up.

**Kills the pinggy / serveo / localhost.run / catbox.moe tunnel hack.** Those tunnels inject HTML interstitials on first request that SpiderMedia happily saves as `.webp` with 200 OK, producing black frames in your scroll-sequence. Never again.

## The one-shot path (v0.9.4+)

### MCP — recommended

```
upload_local_directory(
  local_dir = "./frames/",
  folder = "scroll-sequences/hero"
)
```

Returns:
```json
{
  "success": true,
  "policy": "scroll-sequence",
  "auto_optimize": true,
  "preserve_filename": true,
  "bytes_before_optimize": 201326592,
  "bytes_after_optimize": 8388608,
  "reduction_pct": 96,
  "uploaded": [
    {"filename": "frame_0001.webp", "public_url": "https://media.cdn.spideriq.ai/clients/.../scroll-sequences/hero/frame_0001.webp", "key": "scroll-sequences/hero/frame_0001.webp", "size": 72341},
    ...
  ],
  "warnings": [],
  "totals": {"count": 120, "uploaded": 120, "failed": 0, "bytes": 201326592}
}
```

Because the folder starts with `scroll-sequences/`, the tool:
1. Auto-enables `auto_optimize=true` → runs Sharp locally: every image → WebP quality 75, max 1920px wide.
2. Auto-enables `preserve_filename=true` → the CDN key is `{folder}/{filename}` exactly, so `sys-scroll-sequence` with `{base_url, pattern, count}` resolves to the right URLs.

### CLI

```bash
spideriq media upload ./frames/ --folder scroll-sequences/hero
```

Same auto-enabled defaults for scroll-sequences. Add `--no-auto-optimize` if your frames are already tuned.

### Single file

```
upload_local_file(local_path = "./logo.webp", folder = "brand")
```

Or `spideriq media upload ./logo.webp --folder brand`.

## Weight budget

Server enforces hard ceilings — the MCP tool also shows warnings above the soft line:

| Target folder | Per-file hard | Batch total hard | Soft warning |
|---|---|---|---|
| `scroll-sequences/*` | 500 KB | 20 MB | 200 KB / 10 MB |
| general (everything else) | 20 MB | 500 MB | — |
| `video/*` MIME | 500 MB | 500 MB | — |

If you hit the hard ceiling, the response comes back with `suggested_action` pointing at `auto_optimize=true`. If you're already using that, the files genuinely are too heavy — drop quality or dimensions.

## When to use

- You have 5+ local files to host on the CDN (scroll-sequence frames, logos, pre-produced banners, PDFs).
- You're migrating from Tilda / Wix / Figma and have a local asset dump you want on SpiderMedia.
- You need predictable CDN keys (`preserve_filename=true`) — scroll-sequence `{base_url, pattern, count}` absolutely requires this.
- You want client-side WebP optimization without writing a Sharp pipeline yourself.

## When NOT to use

- Single file → just use `upload_local_file` directly. Still fast, one tool call.
- You're starting from a **video** — use [recipes/scroll-sequence](../scroll-sequence/SKILL.md) instead. `video_to_scroll_sequence` runs `extract_frames` server-side and never round-trips through your local disk.
- You can already reach the files via a public URL → use `media_import_from_url` with the batch form (pass `preserve_filename: true` per item if you need deterministic keys).

## Sharp is an optional peer dep

`auto_optimize=true` needs `sharp`. `@spideriq/mcp-publish` lists it as `optionalDependencies`, so:
- On macOS / Linux x64/arm64 / Windows x64: installed automatically.
- On unsupported platforms or if the install failed: the tool logs a warning and uploads originals.
- If originals blow through the scroll-sequence ceiling, the server returns 400. Install Sharp manually (`npm install sharp`) or switch to manually-pre-optimized frames.

## Common variants

### Filter the directory

```
upload_local_directory(
  local_dir = "./exports/",
  folder = "migrations/homepage",
  pattern = "hero_*.png"
)
```

Only files matching `hero_*.png` get uploaded. Pattern is a simple glob (regex-ish — `*` matches any run of chars, `.` is literal).

### Non-scroll-sequence + preserve filenames

```
upload_local_directory(
  local_dir = "./brand-assets/",
  folder = "brand",
  preserve_filename = true
)
```

For migrations where hard-coded HTML references `brand/logo.png` — `preserve_filename=true` keeps the key exactly.

### Manual quality tuning

```
upload_local_directory(
  local_dir = "./frames/",
  folder = "scroll-sequences/hero",
  quality = 65,        # smaller files, slightly lower quality
  max_width = 1280      # half-resolution for mobile-first
)
```

### Videos for `video_to_scroll_sequence`

```
upload_local_file(
  local_path = "./product-demo.mp4",
  folder = "sources/product-demo"
)
```

Then pass `video_url` to `video_to_scroll_sequence`. 500 MB per-file cap lets you upload a 1080p source without splitting.

## Files in this skill

- `SKILL.md` — this file (human-readable recipe)
- `shell.md` — shell/curl fallback for agents without a TS/MCP runtime
- `impl.ts` — self-contained Node 18+ TypeScript reference (uses native `fetch` + `fs`)

## Key rules

1. **Filenames are preserved on scroll-sequences** — the tool auto-enables `preserve_filename=true` there. For other folders it defaults to `false` (LLM11 prepends a timestamp).
2. **Folder is flat** — don't use subdirectories in the `folder` param; pass the full path like `scroll-sequences/hero` as one string.
3. **Rate limit** — 100 req/min default. Batch endpoint sends ONE request for N files, so you don't burn the limit on 120 frames.
4. **Content-Type** — auto-detected from file extension. Allowed: `.webp`, `.jpg`, `.jpeg`, `.png`, `.gif`, `.pdf`, `.mp4`, `.webm`, `.mov`. Other extensions are rejected client-side.

## Anti-patterns

- DON'T tunnel a local directory via pinggy/serveo/localhost.run and then call `media_import_from_url` against the tunnel URLs. Free tunnels inject HTML interstitials on first request → saved as `.webp` → silent scroll-sequence black frames. The 12h Antigravity #1 saga was exactly this.
- DON'T upload 120 × 1.6 MB JPG frames expecting them to "just work." Without auto-optimize, that's 192 MB — server will return 400. Flip `auto_optimize=true` (default for scroll-sequences) and Sharp compresses them to ~8 MB.
- DON'T upload to a third-party host (catbox.moe, raw.githubusercontent.com, imgur) and reference those URLs from your site. No tenant isolation, no CDN caching, eventual link rot.
- DON'T use `upload_base64` in a loop for 100+ files — the JSON-encoding overhead and the single-shot body limits make it slower than multipart. The batch endpoint is always the right choice for >1 file.

## See also

- [recipes/scroll-sequence](../scroll-sequence/SKILL.md) — for video-sourced scroll heroes (server-side frame extraction)
- [LEARNINGS.md → Media & Scroll-Sequences](../../../LEARNINGS.md#media--scroll-sequences) — gotchas
- [SpiderIQ `/content/help` → `upload_many_local_files`](https://spideriq.ai/api/v1/content/help?format=yaml)
