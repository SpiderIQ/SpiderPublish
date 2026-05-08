#!/usr/bin/env bash
# Install SpiderPublish Antigravity Knowledge Items into ~/.gemini/antigravity/knowledge/
# Idempotent — re-running overwrites with the latest version from this kit.
#
# Usage (from inside a SpiderPublish/ checkout):
#     bash examples/install-antigravity-kis.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/knowledge/antigravity"
TARGET_DIR="${HOME}/.gemini/antigravity/knowledge"

if [[ ! -d "${SOURCE_DIR}" ]]; then
    echo "Error: Antigravity KI source directory not found at ${SOURCE_DIR}" >&2
    echo "       Run this script from inside a SpiderPublish/ checkout." >&2
    exit 1
fi

mkdir -p "${TARGET_DIR}"

KI_COUNT=$(find "${SOURCE_DIR}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
echo "Installing ${KI_COUNT} SpiderPublish Knowledge Items to ${TARGET_DIR}"
echo ""

for ki_dir in "${SOURCE_DIR}"/*/; do
    ki_name=$(basename "${ki_dir}")
    if [[ -d "${TARGET_DIR}/${ki_name}" ]]; then
        echo "  ↻ ${ki_name} (overwriting existing)"
        rm -rf "${TARGET_DIR}/${ki_name}"
    else
        echo "  ✓ ${ki_name} (new install)"
    fi
    cp -r "${ki_dir}" "${TARGET_DIR}/"
done

echo ""
echo "Done. Restart Antigravity to discover the new Knowledge Items."
echo "Or in any conversation, ask: \"List my SpiderIQ Knowledge Items\""
