#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_MD="$ROOT_DIR/When We Were Needed.md"
COVER_IMAGE="$ROOT_DIR/when-we-were-needed.png"
OUTPUT_EPUB="$ROOT_DIR/When We Were Needed.epub"
BOOK_TITLE="When We Were Needed"
AUTHOR="Joshua Szepietowski"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required tool: %s\n' "$1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

require_tool pandoc
require_file "$ROOT_DIR/scripts/manuscript.sh"
require_file "$COVER_IMAGE"

"$ROOT_DIR/scripts/manuscript.sh"
require_file "$SOURCE_MD"

pandoc "$SOURCE_MD" \
  --from markdown \
  --to epub3 \
  --toc \
  --toc-depth=2 \
  --split-level=2 \
  --metadata title="$BOOK_TITLE" \
  --metadata author="$AUTHOR" \
  --metadata lang="en-US" \
  --resource-path="$ROOT_DIR" \
  --epub-cover-image="$COVER_IMAGE" \
  --output "$OUTPUT_EPUB"

printf 'Generated %s\n' "$OUTPUT_EPUB"
