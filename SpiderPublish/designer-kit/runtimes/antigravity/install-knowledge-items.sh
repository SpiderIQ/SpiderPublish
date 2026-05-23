#!/usr/bin/env bash
# Install SpiderPublish Antigravity Knowledge Items into ~/.gemini/antigravity/knowledge/
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.gemini/antigravity/knowledge"
mkdir -p "$DEST"
echo "Installing KIs from $HERE/knowledge-items → $DEST"
for ki in "$HERE"/knowledge-items/*/; do
  name="$(basename "$ki")"
  rm -rf "$DEST/$name"
  cp -r "$ki" "$DEST/$name"
  echo "  ✓ $name"
done
echo
echo "Installed $(ls -1 "$DEST" | wc -l) Knowledge Items. Restart Antigravity to pick them up."
