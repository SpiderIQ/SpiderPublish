# Set Up a SpiderBook Appointment-Booking Flow

When the user asks to add booking, scheduling, calendar, or "book a call", execute these steps.

## Step 1: pick an archetype

SpiderBook ships archetypes — pre-configured flow templates with sensible defaults. Common choices:

- `discovery-15min` — single 15-minute slot, no questions
- `consult-30min` — 30-minute slot with 3 intake questions
- `demo-45min` — 45-minute slot with screen-share link
- `coffee-chat-30min` — 30-minute slot, casual

Custom flows are possible but archetypes cover ~90% of agency cases. Confirm with the user.

## Step 2: create the flow

```
booking_create_flow({
  slug: "discovery",                    // URL becomes /book/discovery
  archetype: "discovery-15min",
  title: "Book a 15-min discovery call",
  host_email: "you@example.com",        // cal.com-side calendar owner
  intake_questions: []                  // archetype defaults; override only if needed
})
// returns { flow_id, slug, cal_link, status: "provisioning" }
```

Provisioning takes ~30 seconds — the engine spins up a cal.com event-type bound to the flow.

## Step 3: poll provisioning status

```
booking_get_flow({ flow_id })
// loop until status === "ready"
```

`status: "ready"` means the cal.com event is live and the embed will render correctly.

## Step 4: embed on a tenant page with the Liquid tag

In your page block (use `rich_text` block):

```liquid
{% booking flow_id="<flow_id>" theme="dark" %}
```

The renderer resolves the `{% booking %}` tag at request time, embedding the cal.com flow inline with your tenant's theme palette applied.

Or attach to an existing page programmatically:

```
content_insert_section_into_page({
  page_id: "<page_with_cta>",
  component_slug: "sys-booking-embed",
  props: { flow_id: "<flow_id>", theme: "dark" },
  position: "after:<cta_block_id>"
})
```

## Step 5: deploy + verify

Standard `content_deploy_site_preview` → `content_deploy_site_production` flow.

Then visit `/book/<slug>` (the standalone booking page) AND the embedded page. Both should render the calendar and accept a test booking.

## Step 6: confirm webhook (optional)

If the user wants notifications on each booking:

```
booking_set_webhook({
  flow_id,
  url: "https://your-crm.com/webhook/booking",
  events: ["booking.created", "booking.cancelled"]
})
```

## Don't

- **Skip the polling step.** Embedding before provisioning completes shows a 404 in the calendar iframe.
- **Hard-code the cal.com URL on the page.** Always use the `{% booking %}` tag — the underlying URL changes if the flow is reprovisioned.
- **Use a slug that conflicts with an existing page.** `/book/<slug>` is reserved; if `<slug>` matches a published page slug, the booking page wins (intentional, but confusing).
