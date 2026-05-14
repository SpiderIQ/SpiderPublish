# recipes/form-from-template

Bootstrap a publishable SpiderFlow form from one of the seeded global templates (P1.M3) in a single agent-callable step. Takes a template slug + optional customisation deltas (rename + override field labels + override logic) and returns a published `flow_id` ready to embed.

## When to use

- A tenant wants an NPS / contact / lead-gen / job-application / event-RSVP form RIGHT NOW and the canonical seeded template fits.
- You're spinning up a demo tenant and need a working form widget in <60s.
- You're migrating off Typeform and want the closest-shape SpiderFlow template as the starting point (then customise).
- An agent wants to stay on the recommended template path instead of authoring fields from scratch (lower hallucination risk; the seed templates are pre-validated against the 14-rule R0-R14 structural validator).

## When NOT to use

- The tenant needs a fully bespoke form that doesn't resemble any seed template — go straight to [forms-quickstart.sh](../../examples/forms-quickstart.sh) or `form_create` + `form_add_field` calls.
- The tenant wants to clone an EXISTING form (not a seed template) — use `form_duplicate` instead.
- The form needs locking + version restore — that's a separate recipe (lock during client review, restore from prior snapshot). This recipe ships the form publishable but unlocked.

## Seeded templates (P1.M3, 5 total)

| Slug | Use case | Field count | Notable features |
|---|---|---|---|
| `lead-gen-quiz` | Multi-step lead qualifier | 8 | Conditional logic (small/medium/large team branches), score variable, recall-token thankyou |
| `contact` | Basic contact form | 4 | Minimal — name / email / phone / message, no logic |
| `nps` | NPS / CSAT survey | 3 | opinion_scale 0-10 + reason short_text + optional email |
| `job-application` | Job application | 7 | file_upload (CV), picture_choice (work mode), short_text (linkedin), date (available from) |
| `event-rsvp` | Event RSVP | 5 | yes_no (attending), number (guest count, hidden when not attending), dropdown (meal pref), short_text (dietary), hidden field for event_id |

## The one-shot calls

```bash
# 1. Pick a template from the global catalog
GET /api/v1/booking/templates/global?kind=form
# → { templates: [{slug, name, description, field_count, ...}], next_cursor }

# 2. (Optional) Inspect one template's full structure before applying
GET /api/v1/booking/templates/global/{template_slug}
# → { name, description, flow: {fields[], welcome_screen?, thankyou_screen?, logic?, hidden_fields?, variables?}, ... }

# 3. Create the form from the template (sentinel-business resolved server-side)
POST /api/v1/booking/flows
Body: {
  "name": "<custom name | template default>",
  "kind": "form",
  "template_id": "<template_slug>",
  // optional customisation deltas:
  "field_overrides": { "q1": {"label": "Your work email"} },
  "logic_overrides": [],
  "hidden_field_overrides": { "event_id": "evt_abc123" }
}
# → { flow_id, status: "draft", ... }

# 4. Publish — Phase 11+12 dry_run/confirm_token gated
POST /api/v1/booking/flows/{flow_id}/publish?dry_run=true
# → { dry_run: true, preview: {field_count, has_logic, ...}, confirm_token, expires_at }
POST /api/v1/booking/flows/{flow_id}/publish?confirm_token=cft_xxx
# → { status: "active", embed_endpoint: "/book/{flow_id}", ... }
```

**MCP tools** — kitchen-sink `@spideriq/mcp@1.14.5`:

- `form_list_templates({kind: "form"})` — list seeded templates
- `form_get_template({template_slug})` — full template inspection
- `form_create({name?, template_id, field_overrides?, logic_overrides?, hidden_field_overrides?})` — create from template
- `form_publish({flow_id, dry_run?: true, confirm_token?})` — publish via 2-phase gate
- `form_get_embed_snippet({flow_id, mode: "inline"|"popup", button_text?})` — emit copy-paste snippet

## Auth

PAT (`Authorization: Bearer <client_id>:<api_key>:<api_secret>`). Tenant binding via `X-Selected-Client-Id` header OR `/projects/{project_id}/` URL prefix (Phase 11+12).

## Recovery / errors

- **`404 template_not_found`** — seed template slug doesn't exist. Call `form_list_templates` first to confirm. Misspelled slugs (`leadgen-quiz` instead of `lead-gen-quiz`) are a common cause.
- **`422 validation_failed` on field_overrides** — your override is changing a field's `type` (not allowed; types are pinned by the template). Field-overrides may change `label` / `description` / `placeholder` / `required` / `options[].label` but not `type` or `id`. Drop the offending key and retry.
- **`423 form_locked` on publish** — never happens on a freshly created form (locking is a separate operation). If you see this, you're chaining onto a pre-existing locked form — call `form_unlock` first if you're authorised.
- **`409 confirm_token_consumed`** — the confirm_token from your dry_run was already used. Re-issue with another dry_run call.

## Companion recipe

For ongoing form lifecycle once it's live, see:
- [shared/core-skills/forms/SKILL.md](../../core-skills/forms/SKILL.md) — full surface reference
- [shared/recipes/lock-during-review/](../lock-during-review/) — pattern that applies the same way for forms (`form_lock` / `form_unlock` / `form_list_versions` / `form_restore_version`)
