# Forms — Premium Design Guide

> Author polished Forms — not the default look. This guide is the long-form companion to [core-skills/forms/](../../core-skills/forms/) and the [build-lead-gen-form](../../recipes/build-lead-gen-form/), [design-a-form](../../recipes/design-a-form/), and [idap-fill-from-form](../../recipes/idap-fill-from-form/) recipes.
>
> **Read first:** the [Phase 0 ritual in AGENTS.md](../../content/agents-catalog.md) — never author a form against a stale MCP bundle. Then the [forms SKILL.md](../../core-skills/forms/SKILL.md) for the bare authoring surface.

This guide stays disciplined about what is shipped vs what is queued. Anything marked **(plumbing-fix queued)** is a known design-system gap — the API will accept the field today, but the renderer may not honour it yet. Use it anyway; the field is stored and will start rendering when the fix lands.

---

## 1. Form data model

A Form is a row in the `booking_flows` table with `kind='form'`. The shape that matters:

```json
{
  "flow_id": "uuid",
  "kind": "form",
  "name": "Free trial signup",
  "status": "draft | active | archived",
  "schema_version": "1.0.0",
  "flow": [
    {
      "id": "form-step",
      "type": "form",
      "label": "Form",
      "fields": [ { "id": "...", "type": "...", "label": "...", ... } ]
    }
  ],
  "hidden_fields": [ { "key": "utm_source", "label": "UTM Source", "default_value": "direct" } ],
  "variables": { "lead_score": { "type": "number", "default": 0 } },
  "logic": [ { "trigger_field": "...", "condition": { ... }, "actions": [ { ... } ] } ],
  "welcome_screens": [ ... ],
  "thankyou_screens": [ ... ],
  "theme": { "preset": "card-light", "tokens": { "--primary": "#e8556f", ... } }
}
```

Forms today ship a single `FormStep` with all fields in `flow[0].fields`. Multi-step (one question per step) is achieved at render time via the `next` button — the data shape stays flat. The 6-bundled-preset model lives under `theme`; per-question media (image / video / background) goes on `field.media`.

---

## 2. The 15 field types

| Type | Use case | Notes |
|---|---|---|
| `short_text` | Names, company names, free-form one-liners | Min/max length via `validation` |
| `long_text` | Open-ended feedback, "tell us more" | Textarea; max 2000 chars |
| `email` | Email capture | Built-in shape validator + (optional) domain blocklist |
| `phone` | Phone capture | Defaults to E.164 input mask; can be relaxed |
| `number` | Numeric (age, quantity, scale) | Optional min/max/step |
| `dropdown` | Single-pick from ≤ 50 options | `options[].value` must be unique |
| `checkbox` | Multi-pick from N options | Same shape as dropdown — `options[].value` unique |
| `picture_choice` | Visual single-pick (logos, color swatches, product cards) | Every option requires `image_url` |
| `rating` | 1-5 / 1-10 star/heart/thumb | `shape: 'star' \| 'heart' \| 'thumb'` (required) |
| `nps` | 0-10 NPS | Fixed scale, no override |
| `opinion_scale` | 1-N likert | `steps` in 5-11 (anchored labels per end) |
| `date` | Single date | ISO 8601; pickers for keyboard + touch |
| `file_upload` | Resume / portfolio / one-off attachment | `accept[]` of MIME types; `max_size_mb` |
| `statement` | Display-only narration ("step 2 of 3 — almost done!") | No answer collected |
| `yes_no` | Binary decision | Renders as two large pill buttons |

IDAP-anchored field types (forms can populate CRM columns directly):

| Type | Use case |
|---|---|
| `url` | Capture a URL with valid-URL validation |
| `country` | Country picker (ISO 3166-1 alpha-2) |
| `region` | State/province (depends on selected `country`) |
| `postal_code` | Locale-aware postal-code regex |
| `address` | Street address (one-line capture; pairs with `country` + `region`) |
| `datetime` | Date + time (ISO 8601) |
| `currency` | Amount + currency picker (ISO 4217) |
| `place` | Google-Places-backed autocomplete (graceful free-text fallback if no API key) |

See [`shared/recipes/idap-fill-from-form/SKILL.md`](../../recipes/idap-fill-from-form/SKILL.md) for the field-type ↔ CRM-column compatibility matrix.

---

## 3. Conditional logic

Each rule has the shape:

```json
{
  "trigger_field": "q3",
  "condition": {
    "type": "field",
    "field": "q3",
    "op": "equals",
    "value": "large"
  },
  "actions": [
    { "type": "jump", "target": "field", "target_id": "q_enterprise" }
  ]
}
```

**Condition operators:** `equals`, `not_equals`, `contains`, `not_contains`, `greater_than`, `less_than`, `is_empty`, `is_not_empty`. Group conditions with `{type: "and"|"or", conditions: [...]}` for compound logic.

**Action types:**
- `jump` to `target: "field"` (jump to a sibling field) or `target: "thankyou"` (skip to thank-you screen)
- `add` / `subtract` / `multiply` / `divide` — mutate a declared `variable` (use this to compute a lead-score or a quote)

**Validate locally before publish:**
```
form_validate_logic({ rules: [...] })
# Returns errors[] for unreferenced fields, circular jumps, ambiguous compound conditions.
```

---

## 4. Hidden fields for tracking

Capture URL parameters at form-load time (no user input). Common patterns:

```js
hidden_fields: [
  { key: "utm_source",   label: "UTM Source",   default_value: "direct" },
  { key: "utm_medium",   label: "UTM Medium",   default_value: "" },
  { key: "utm_campaign", label: "UTM Campaign", default_value: "" },
  { key: "ref",          label: "Referrer",     default_value: "" },
  { key: "lead_score",   label: "Lead Score",   default_value: "0" }
]
```

The embed loader auto-injects `?utm_*` query params at load time. You can also override via `data-prefill-<key>="value"` on the embed tag.

---

## 5. The 9-step authoring flow

```
0. Phase 0 — Verify your MCP bundle (≤30 s — see AGENTS.md)
1. booking_flow_list({ kind: "form" })       — list existing flows to avoid name collisions
2. booking_template_list({ kind: "form" })   — browse the seeded form templates
   booking_template_clone({ template_id })   — clone one as a starting point (skip if authoring from scratch)
   OR
   form_create({ name, fields, theme })      — fresh blank
3. form_add_field({ flow_id, field })         — incrementally extend
   form_add_choice({ flow_id, field_id, option })
4. form_add_logic_rule({ flow_id, rule })     — branching
   form_declare_variable({ flow_id, name, declaration })
   form_add_hidden_field({ flow_id, hidden_field })
5. form_validate({ flow })                    — full-flow client-side check (no API call)
   form_validate_logic({ rules })             — rules only
6. form_test_submit({ flow_id, answers })     — sandbox submit, no real lead row
7. form_publish({ flow_id, dry_run: true })   — preview + confirm_token
   form_publish({ flow_id, confirm_token })   — commit (status flips to active)
8. form_get_embed_snippet({ flow_id, mode })  — local-only snippet generator
9. content_visual_check({ page_url })         — empirical proof the form rendered
   Assert: response.dom.shadow_hosts.includes("spideriq-form")
```

The same loop in CLI form:

```bash
spideriq form list --kind form
spideriq form create --name "..." --field 'fields=[...]'
# ... fields, logic, hidden fields ...
spideriq form publish <flow_id>           # → preview + confirm_token
spideriq form publish <flow_id> --confirm <token>   # → status: active
spideriq form embed-snippet <flow_id> --mode popup
```

---

## 6. Premium design options

This is the section to read when you want a polished form. The shipped surface is intentionally narrow — six presets + arbitrary `--token` overrides — because every premium pattern below maps cleanly to one of those primitives.

### 6.1 Theme / preset system

Six bundled presets, served by the renderer at `apps/forms/src/styles/presets/`:

| Preset | Look | When to pick |
|---|---|---|
| `card-light` | Centered white card on a soft tinted background | Default-safe; B2B SaaS, signup forms, surveys |
| `fullscreen-dark` | One question per viewport, white text on a deep background | Brand storytelling, premium positioning |
| `conversational-left` | Left-aligned questions with a sidebar containing media | "Walking with the customer" feel; warmer brands |
| `form-on-image` | Form overlay on a full-bleed background image | Lead-gen with a strong product hero |
| `minimal-print` | Serif headlines, restrained palette, generous whitespace | Editorial, education, real-estate |
| `agency-bold` | Heavy headlines, contrast accents, square corners | Creative agencies, portfolio gates |

```js
theme: {
  preset: "fullscreen-dark",
  tokens: {
    "--primary": "#e8556f",
    "--bg": "#0a0a0a",
    "--text": "#f5f5f5",
    "--font-heading": "'Inter Display', sans-serif"
  }
}
```

**Token cap:** 64 entries, each value ≤ 256 chars. Key shape `--<kebab>` enforced by Zod at publish time — a typo (`primary` without `--`) fails fast.

**Known limitation (plumbing-fix queued):** theme application to the form's shadow host is the focus of an open initiative (`forms-design-plumbing-fix`). The fields are stored on every flow; the renderer's CSS-variable injection is being routed through `:host` so per-tenant themes pierce the shadow boundary. Set fields are stored for when the fix lands.

### 6.2 Layout variants

Bundled with the preset, but switchable per-flow at the renderer level by setting `--layout-mode`:

- `full-page` — one question per viewport (great for `fullscreen-dark`)
- `centered-card` — single card on a tinted page (the `card-light` default)
- `side-by-side` — image + form 50/50 (use with `conversational-left`)
- `full-bleed-background` — form floating on a hero image (use with `form-on-image`)

```js
tokens: {
  "--layout-mode": "side-by-side",
  "--layout-max-width": "720px"
}
```

### 6.3 Field-level styling overrides

Per-field width, label position, and help-text placement:

```js
field: {
  id: "company",
  type: "short_text",
  label: "Company name",
  layout: {
    width: "50%",                    // "25%" | "33%" | "50%" | "66%" | "75%" | "100%" (default)
    label_position: "floating",       // "top" | "left" | "floating"
    help_text_placement: "below"      // "below" | "tooltip"
  }
}
```

Pair `width` on consecutive fields to form rows (`50% + 50%`, `33% + 33% + 33%`). The renderer collapses fields with `width !== "100%"` into one flex row whenever they're consecutive in the field array.

### 6.4 Welcome & thank-you screens

Both screens carry the same shape:

```js
welcome_screens: [{
  id: "welcome",
  headline: "Tell us about your trial",
  body: "It takes about a minute.",
  cta_text: "Start",
  media: { type: "image", url: "https://media.cdn.spideriq.ai/forms/<slug>/hero.webp" }
}]

thankyou_screens: [{
  id: "thanks",
  headline: "Thanks — we'll be in touch within 1 business day.",
  body: "If you don't see our email, check spam.",
  cta_text: "Back to acme.com",
  cta_url: "https://acme.com"
}]
```

Multiple thank-you screens are picked by `logic` rules — branch on the answers to show a different message to enterprise leads vs SMB leads.

### 6.5 Progress indicators

Set `--progress-style` on the theme:

- `none` — no indicator (matches `minimal-print`)
- `step-counter` — `Step 2 / 5` text (matches `conversational-left`)
- `progress-bar` — filling horizontal bar (matches `card-light`, `agency-bold`)
- `dot-pager` — N dots, filled progressively (matches `fullscreen-dark`)

### 6.6 Transitions

`--transition-style`:

- `instant` — no animation (fastest, best for screen readers)
- `fade` — 200ms cross-fade between questions
- `slide` — 280ms horizontal slide (the Typeform-classic feel)

`prefers-reduced-motion: reduce` always wins and forces `instant` regardless of the token value.

### 6.7 Submit-button customization

```js
tokens: {
  "--submit-label": "Get my free trial",
  "--submit-color": "#e8556f",
  "--submit-text-color": "#ffffff",
  "--submit-position": "center"          // "left" | "center" | "right" | "stretch"
}
```

For per-step submit labels (e.g. "Next" → "Submit" on the last step), the renderer auto-detects the last step and uses `--submit-label-final` when set.

### 6.8 Brand assets

```js
theme: {
  tokens: {
    "--logo-url": "https://media.cdn.spideriq.ai/forms/<slug>/logo.svg",
    "--logo-position": "top-left",           // "top-left" | "top-center" | "top-right" | "hidden"
    "--favicon-url": "https://media.cdn.spideriq.ai/forms/<slug>/favicon.png",
    "--og-image-url": "https://media.cdn.spideriq.ai/forms/<slug>/og-image.webp",
    "--og-title": "Apply for the Acme beta",
    "--og-description": "60-second application — we reply within 24h"
  }
}
```

`og:*` keys only matter when the form ships at the standalone `/f/<flow_id>` URL — the iframe-embedded surface never gets crawled.

### 6.9 Accessibility

Built in (don't override unless you know what you're doing):

- Every field has an associated `<label>` (no placeholder-as-label anti-pattern)
- Required fields get `aria-required="true"` + a visible `*` indicator
- The progress indicator has `role="progressbar"` + `aria-valuenow` updated per step
- Keyboard navigation: `Tab` cycles fields, `Enter` advances when valid, `Shift+Tab` goes back
- Focus rings respect `--focus-color` (defaults to `--primary`)
- `prefers-reduced-motion: reduce` forces instant transitions
- Color contrast: presets meet WCAG AA (≥ 4.5:1 for body text). When overriding `--text` / `--bg`, validate with a contrast tool.

---

## 7. Validation — the 14-rule validator (R0-R14)

`form_validate` runs the whole flow through 14 structural rule classes — entirely client-side, no API call. Catch problems before publish.

| Rule | Catches |
|---|---|
| R0 | Top-level shape — `kind`, `schema_version`, `flow[]` present |
| R1 | `flow[0]` is a FormStep with at least one field |
| R2 | Every field has unique `id` (no duplicate field keys) |
| R3 | Every field's `type` is in the allowed enum |
| R4 | Per-type required keys (dropdown needs `options[]`, picture_choice needs `image_url` on each option, etc) |
| R5 | `options[].value` is unique within a field |
| R6 | Hidden-field `key` is unique across all hidden fields |
| R7 | `variables` have valid type + default that matches type |
| R8 | Logic rules reference fields that exist (no dangling `trigger_field` / `condition.field` / `actions[].target_id`) |
| R9 | Logic conditions use valid operators for the field type (no `greater_than` on `email`) |
| R10 | Welcome / thank-you screens have non-empty `headline` |
| R11 | `theme.tokens` keys match `--<kebab>` and values ≤ 256 chars |
| R12 | `theme.preset` is a known slug (warning only — forward-compat) |
| R13 | No circular jumps in logic (`q1 → q2 → q1`) |
| R14 | `file_upload` fields declare `accept[]` and `max_size_mb` |

The VSCode / Cursor / Antigravity extension surfaces these as red squiggles directly in the JSON editor.

---

## 8. Three embed methods

### 8.1 Standalone

```
https://<tenant-domain>/f/<flow_id>
```

Used for QR codes, social bio links, ad campaigns. The standalone surface honours `og:*` tokens + favicon, so social shares look branded.

### 8.2 Inline embed

```html
<div data-spiderflow-flow="<flow_id>" data-spiderflow-mode="inline"></div>
<script async src="https://embed.spideriq.ai/v1/loader.js"></script>
```

Drops an iframe inside the host page. Form chrome (header, progress bar) is opt-out via `data-spiderflow-hide-headers="true"` for tighter integrations.

### 8.3 Popup embed

```html
<button data-spiderflow-flow="<flow_id>" data-spiderflow-mode="popup"
        data-spiderflow-trigger-text="Get started">Get started</button>
<script async src="https://embed.spideriq.ai/v1/loader.js"></script>
```

Button → modal iframe. The iframe doesn't fetch until first click — perfect for above-the-fold CTAs without paying the form bundle cost upfront.

**Full data-attribute catalog:**

| Attribute | Required | Default | Notes |
|---|---|---|---|
| `data-spiderflow-flow` | yes | — | The form's `flow_id` |
| `data-spiderflow-mode` | no | `inline` | `inline` or `popup` |
| `data-spiderflow-domain` | no | `forms.spideriq.ai` | Override for custom iframe domain |
| `data-spiderflow-trigger-text` | no | `Open Form` | Popup only — button label |
| `data-spiderflow-on-complete` | no | — | Dotted path (`window.myCallback`) — NO `eval` |
| `data-spiderflow-auto-open` | no | `false` | Popup only — open immediately on mount |
| `data-spiderflow-hide-headers` | no | `false` | Suppress form chrome |
| `data-prefill-<key>` | no | — | Any number of these — feeds `hidden_fields` |

---

## 9. Submission contracts

When the customer submits, the loader posts:

```
POST https://<tenant-domain>/api/v1/booking/<flow_id>/submit
Content-Type: application/json
Idempotency-Key: <uuid>

{
  "answers": { "q1": "alice@acme.com", "q2": "Acme", "q3": "small" },
  "hidden_fields": { "utm_source": "google", "utm_campaign": "trial" },
  "completion_meta": { "time_to_complete_ms": 47210 }
}
```

**Response on success** (`200 OK`):

```json
{ "submission_id": "uuid", "status": "received", "thankyou_redirect_url": "..." }
```

**Response on validation error** (`400` with structured envelope per Wave 3):

```json
{
  "error": {
    "code": "field_required",
    "message": "...",
    "what_you_sent": { "answers": { ... } },
    "what_was_expected": { "answers.q1": "non-empty string" }
  }
}
```

`Idempotency-Key` is generated client-side by the loader (UUIDv4) — duplicate POSTs with the same key return the original `submission_id` rather than creating duplicate leads.

---

## 10. Common gotchas

| # | Trap | Fix |
|---|---|---|
| 1 | "form_create returns 422 — business_id required" | Pass any business UUID owned by the brand. The constraint is being lifted for `kind='form'` in the next backend wave. |
| 2 | "form_publish returns 422 — title required" | Pass `title: "Form"`, `length_minutes: 1`, `team_id: 0`. These are Cal.com-required but ignored for kind='form'. |
| 3 | "/book/&lt;flow_id&gt; returns 404" | Until status flips to `active`, the route 404s. Re-check `form_publish` actually consumed the `confirm_token`. The canonical URL is now `/f/<flow_id>` — `/book/<flow_id>` 301-redirects. |
| 4 | "Embed shows 'Form not found'" | `flow_id` typo, or the form was published on a different tenant. The embed loader looks up the form on the iframe-domain tenant, not the host-page domain. |
| 5 | "Submit returns 400 — Idempotency-Key required" | The loader auto-generates this, but if you're POSTing manually, include `Idempotency-Key: <uuid>`. |
| 6 | "form_test_submit returns 403 — not a load-test client" | Today honoured only for `LOAD_TEST_CLIENT_ID`. Workaround: real flow + unique answer payload + manual cleanup of the test row. |
| 7 | "Theme override silently ignored" | Verify your token key matches `--<kebab>`. `primary` fails Zod; `--primary` works. Check the publish response for `theme: { tokens: {...} }` reflecting your values. |
| 8 | "Picture-choice options render without images" | Every option must carry `image_url`. R4 catches this in `form_validate`. |
| 9 | "Logic rule jumps to a removed field" | When you delete a field, `form_remove_field` server-side scrubs referencing rules. But if you `form_update` the flow in bulk and forget to update rules, R8 catches it. |
| 10 | "Two embeds on one page conflict" | The loader is multi-instance safe — each embed scopes to its own iframe via `flowId` matching. If you see weird cross-talk, your custom `on-complete` handler is sharing global state. Scope it. |

---

## 11. Cross-links

- [shared/core-skills/forms/SKILL.md](../../core-skills/forms/SKILL.md) — bare authoring surface + template catalog
- [shared/core-skills/forms/schema.yaml](../../core-skills/forms/schema.yaml) — 21 MCP method shapes
- [shared/recipes/build-lead-gen-form/](../../recipes/build-lead-gen-form/) — end-to-end build recipe
- [shared/recipes/design-a-form/](../../recipes/design-a-form/) — preset + token + per-question media recipe
- [shared/recipes/idap-fill-from-form/](../../recipes/idap-fill-from-form/) — CRM-fill recipe with field-type matrix
- [shared/core-skills/booking/SKILL.md](../../core-skills/booking/SKILL.md) — sibling kind='booking' surface (cal.com-backed)
- [shared/content/agents-catalog.md](../../content/agents-catalog.md) — Phase 0 ritual, tool-discovery channels, Wave 3 contracts
