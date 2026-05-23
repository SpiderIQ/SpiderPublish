#!/usr/bin/env bash
# audit-driven-edit.sh — single-roundtrip authoring with the P5 _rules + _audit envelope.
#
# Walks through:
#   1. content_get_page WITH audit_level=warnings — read the current page state + _page_audit
#   2. page_insert_section with dry_run=true — read _rules to learn the canonical path
#   3. page_insert_section with confirm_token + audit_level=all — confirm + read _audit
#
# Replays the scenario that broke a high-profile customer site early 2026-05:
# inserting sys-scroll-sequence with empty props.frames lands a blank canvas
# at runtime. P5 surfaces the trap on dry_run via authoring_hints.preferred_path
# AND on the success response via _audit.block_level.

set -euo pipefail

: "${SPIDERIQ_PAT:?Set SPIDERIQ_PAT=<your-pat-triple>}"
: "${SPIDERIQ_PROJECT_ID:?Set SPIDERIQ_PROJECT_ID=<cli_xxx-or-uuid>}"
: "${SPIDERIQ_PAGE_ID:?Set SPIDERIQ_PAGE_ID=<page-uuid>}"

API="https://spideriq.ai/api/v1"
H_AUTH="Authorization: Bearer ${SPIDERIQ_PAT}"
H_JSON="Content-Type: application/json"

echo
echo "STEP 1 — Get the page with audit_level=warnings"
echo "================================================"
curl -sS -H "${H_AUTH}" \
  "${API}/dashboard/projects/${SPIDERIQ_PROJECT_ID}/content/pages/${SPIDERIQ_PAGE_ID}?audit_level=warnings" \
  | jq '{slug, title, blocks_count: (.blocks | length), audit_summary: ._page_audit.summary, audit_findings: ._page_audit | to_entries | map(select(.value | type == "array" and length > 0)) | from_entries}'

echo
echo "STEP 2 — Dry-run insert sys-scroll-sequence (intentionally with empty props)"
echo "============================================================================"
DRY_RUN=$(curl -sS -X POST -H "${H_AUTH}" -H "${H_JSON}" \
  "${API}/dashboard/projects/${SPIDERIQ_PROJECT_ID}/content/pages/${SPIDERIQ_PAGE_ID}/insert-section?dry_run=true" \
  -d '{"component_slug": "sys-scroll-sequence", "props": {}}')

echo "${DRY_RUN}" | jq '{
  preview: .preview,
  confirm_token: .confirm_token,
  rules_summary: {
    component: ._rules.component_slug,
    intrinsic_count: (._rules.intrinsic | length),
    authored_preferred_path: ._rules.authored.preferred_path,
    authored_must_set: ._rules.authored.must_set,
    cross_cutting_count: (._rules.cross_cutting | length)
  }
}'

PREFERRED=$(echo "${DRY_RUN}" | jq -r '._rules.authored.preferred_path // empty')
TOKEN=$(echo "${DRY_RUN}" | jq -r '.confirm_token')

if [ -n "${PREFERRED}" ]; then
  cat <<MSG

>>> AUTHOR GUIDANCE: ${PREFERRED}
>>>
>>> A real agent would STOP here and switch to the named tool. For this
>>> walkthrough we proceed with the manual path AND populate frames so the
>>> _audit block lands clean.

MSG
fi

echo
echo "STEP 3 — Confirm insert with populated frames + audit_level=all"
echo "================================================================="
curl -sS -X POST -H "${H_AUTH}" -H "${H_JSON}" \
  "${API}/dashboard/projects/${SPIDERIQ_PROJECT_ID}/content/pages/${SPIDERIQ_PAGE_ID}/insert-section?confirm_token=${TOKEN}&audit_level=all" \
  -d '{"component_slug": "sys-scroll-sequence", "props": {"frames": ["https://cdn.example.com/f1.webp", "https://cdn.example.com/f2.webp", "https://cdn.example.com/f3.webp"]}}' \
  | jq '{success, page_id, new_block_id, insertion_index, blocks_count, audit_summary: ._audit.summary, audit_findings: ._audit | to_entries | map(select(.value | type == "array" and length > 0)) | from_entries}'

cat <<MSG

DONE. Inspect the output:
  - STEP 1 shows _page_audit on a get with severity filter 'warnings'
  - STEP 2 shows the _rules envelope: intrinsic + authored + cross_cutting
  - STEP 3 shows the _audit envelope on the success response

If the agent had inserted with empty frames in STEP 3, the response would
carry _audit.block_level = [{rule_id: "insertion.scroll_sequence_empty_frames",
severity: "error", ...}] — flagging the trap immediately.

Try variations:
  - audit_level=off on STEP 1 to skip the auditor entirely (cheapest)
  - audit_level=errors on STEP 3 to suppress warnings + info
  - omit "frames" on STEP 3 to see the empty-frames error fire on _audit
MSG
