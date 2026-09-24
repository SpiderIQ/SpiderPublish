---
name: design-reusable-sections
description: "Rules for building a SpiderPublish section (component) or page template that other brands can reuse: colours only through theme tokens (--primary, --primary-fg, --surface, --surface-elevated, --subtle, --heading, --body-text, --overlay/-fg), CSS in the css field with :host, no Tailwind inside the shadow DOM, JS through root not document, every word a prop, no fake social proof, light + dark + responsive checks, content_visual_check. Use whenever the user asks to design, author or hand in a component, section, marketplace asset or page template, asks 'why is my component rejected with 422', 'which colour variables can I use', or 'why does my section look wrong on another site'."
---
# Design Reusable Sections & Page Templates

Use this when you build a **section** (a component such as a header, hero, pricing table or FAQ) or a **page template** that other brands will reuse — marketplace assets, agency starter pages, anything a second site will copy.

The bar is not "it looks good". It is: **someone else's brand colours and words go in, and it still looks deliberate.** A section that only looks right in your palette is not finished.

Full technical reference: [components.md in the public SpiderPublish skill](https://github.com/SpiderIQ/skills/blob/main/skills/SpiderPublish/spiderpublish/references/components.md).

## 1. Colours only through theme tokens

Every colour resolves through a token the renderer emits for each site. Write `var(--token, <fallback>)`, never a bare colour.

| Token | Use it for |
|---|---|
| `--primary` | brand colour: buttons, links, highlights |
| `--primary-fg` | text or icons **on** a `--primary` background — never `#fff` (unreadable on a yellow brand) |
| `--surface` | page and section backgrounds |
| `--surface-elevated` | cards and raised panels |
| `--subtle` | borders, dividers, muted fills |
| `--heading` | headings |
| `--body-text` | paragraphs |
| `--overlay` / `--overlay-fg` | a dark scrim over a photo or video, and the text on it — the only "always light" text |
| `--success` `--warning` `--danger` (+ `-fg`) | status messages only |
| `--font-heading` `--font-body` `--font-mono` | fonts |

```css
/* RIGHT */  .cta   { background: var(--primary, #eebf01); color: var(--primary-fg, #0a0a0a); }
/* RIGHT */  .card  { background: var(--surface-elevated, #111113); border: 1px solid var(--subtle, #1a1a1d); }
/* WRONG */  .cta   { background: #1d4ed8; color: #ffffff; }          /* fixed colours  */
/* WRONG */  .title { color: var(--brand-primary, #111); }            /* invented token */
```

- No fixed colours (hex, rgb, hsl, names), except inside `box-shadow`, `text-shadow`, `filter`, `backdrop-filter`. `transparent`, `currentColor` and `inherit` are always fine.
- Never invent a token. Nothing emits `--accent`, `--secondary`, `--muted`, `--text-muted`, `--border`, `--gold`, `--white` or `--brand-*` — their fallback would render on every site forever.
- **Marketplace (shared) components are rejected with a 422** that lists every violation and the substitution to make. Your own site's components are not checked — follow the rule anyway if they should adapt to a theme change.

## 2. Sections render inside a shadow DOM

- CSS goes in the component's **`css` field**, not a `<style>` tag inside `html_template`.
- Style the section's own box with `:host { … }`.
- **Tailwind / utility classes do not work** inside the shadow root. They look right in a local preview and render unstyled on a real site. Write real CSS.
- JavaScript reaches its own markup through **`root`**: `root.querySelector('.faq-item')`. `document.querySelector(...)` silently finds nothing — the section stays inert.

## 3. Every word is a prop

All text, links and images are props with sensible defaults in `props_schema` / `default_props`, so a site owner changes the words without touching HTML.

## 4. No made-up proof

No invented testimonials, names, faces, logos, star ratings, review counts, "10,000+ customers" or award badges. A template ships to real businesses — use neutral placeholder copy ("Customer quote goes here") or an empty state.

## 5. Images that work everywhere

Real images that read on light **and** dark backgrounds, hosted in the media library (`media_ingest_url` / `upload_local_file`), each with alt text. No broken links, no flat grey or black placeholder blocks.

## 6. Responsive

Check at 375 px, 768 px and 1440 px. No fixed heights on anything holding text; long headings wrap instead of overflowing.

## 7. Light and dark

Check the page with a light palette **and** a dark one, and with a dark **and** a bright `primary_color`. `content_update_settings` sets `primary_color`, `surface_color`, `surface_elevated_color`, `subtle_color`, `body_text_color` and `heading_color` for the site you are bound to.

## 8. Reuse before you build

List what exists first: `content_list_marketplace_components` with a `category` (hero, features, pricing, social-proof, content, forms, team, header, footer, cta, faq) and `content_list_page_templates`. Adapting an existing section beats writing a new one.

## 9. Building pages

- Create pages with `template: "default"`, not `"blank"` — blank drops the whole layout and can leave text invisible on a dark site.
- Add sections as component blocks (`page_insert_section`). A raw `<spideriq-cmp>` tag in HTML never renders.
- Theme files (`template_apply_theme`, `template_upsert`, `template_delete`) are shared by **every site in the workspace** — don't use them to style one page.

## 10. Readable and usable

Body-text contrast at least 4.5 : 1, visible focus on links and buttons, real `<a>` / `<button>` elements for anything clickable.

## Verify like a reviewer

`content_visual_check` with `{ "page_url": "<page URL>", "viewport": "desktop" }`, then `"mobile"`. Look at the screenshot. For sections, `dom.shadow_hosts` lists `spideriq-cmp`. Never judge from `body_text_preview` — text inside a shadow root does not appear there even when everything works.
