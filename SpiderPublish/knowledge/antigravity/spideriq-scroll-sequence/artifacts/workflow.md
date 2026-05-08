# Build a Scroll-Linked Hero from a Video

When the user asks for a cinematic scroll hero, scroll-driven video, or Apple-style scroll animation, execute these steps.

## Step 1: upload the source video

```
media_upload({
  file: "<path-to-video.mp4>",
  category: "scroll-sequences"
})
// returns { media_id, url, duration_seconds, dimensions }
```

Acceptable formats: MP4, MOV, WebM. Recommended: 1080p, 30fps, 5–10 seconds. Longer videos = more frames = larger payload.

## Step 2: extract frames server-side via ffmpeg

```
media_extract_frames({
  media_id: "<from step 1>",
  count: 60,                            // typical: 30-90 frames
  format: "jpg",                        // jpg = smaller; webp = best compression
  quality: 80
})
// returns { base_url, pattern: "frame-{i}.jpg", count }
```

The ffmpeg pipeline runs in the worker fleet; typical job time is 5–15 seconds. The output frames live at `media.cdn.spideriq.ai/scroll-sequences/<media_id>/frame-N.<ext>`.

## Step 3: insert the sys-scroll-sequence component

```
content_insert_section_into_page({
  page_id: "<target_page>",
  component_slug: "sys-scroll-sequence",
  props: {
    base_url: "<from step 2>",
    pattern: "frame-{i}.jpg",
    count: 60
  },
  position: "start"
})
```

The component is a Tier 3 wrapper that renders a sticky-positioned `<canvas>` inside Shadow DOM, polls for GSAP + ScrollTrigger to load (CDN-allowlisted), then animates frame-by-frame as the user scrolls.

## Step 4: verify the rendered template

The page's layout template MUST NOT have `overflow-x: hidden` on `<html>` or `<body>` — that breaks `position: sticky` and the canvas pins to the section instead of the viewport (the canvas scrolls past the top of the screen and the user just sees a black background; classic broken-scroll-sequence symptom).

If the user has customized their layout template:

```
content_get_section_source({ section: "layout" })
// scan for "overflow-x: hidden" or "overflow: hidden" on html / body
// if present, change to "overflow-x: clip" — clip prevents horizontal scroll without breaking sticky
```

## Step 5: deploy + verify

Standard deploy flow. Then load the page in a browser and scroll slowly through the section.

Verification:
- Frames advance 1:1 with scroll position
- No visible flash between frames
- Canvas pins to viewport while in section, releases at section bottom
- Devtools `getImageData` on the canvas returns non-zero pixel data

## Performance notes

- 60 frames at 1080p WebP ≈ ~3 MB total — acceptable on 4G
- 120 frames at 1080p WebP ≈ ~6 MB — desktop-only; switch to 720p for mobile
- Frame count should match section scroll length: ~10-20 frames per viewport-height of scroll

## Don't

- **Use 4K source video.** Extract at 1080p max; the canvas downsamples either way.
- **Skip Step 4 (overflow check).** It's the #1 cause of "scroll sequence renders black" reports.
- **Use `category: "header"` on the wrapper page.** That auto-suppresses chrome — fine for a full-bleed hero page, breaks navigation if it's a section inside a normal page.
