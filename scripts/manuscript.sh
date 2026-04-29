#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHAPTERS_DIR="$ROOT_DIR/chapters"
OUTPUT_FILE="$ROOT_DIR/When We Were Needed.md"
BOOK_TITLE="When We Were Needed"
AUTHOR="Joshua Szepietowski"

if [[ ! -d "$CHAPTERS_DIR" ]]; then
  echo "Could not find chapters directory: $CHAPTERS_DIR" >&2
  exit 1
fi

sort_key_for_phase() {
  local name
  name="$(basename "$1")"

  if [[ "$name" =~ ^Phase[[:space:]]+([0-9]+) ]]; then
    printf "%06d\t%s\n" "${BASH_REMATCH[1]}" "$1"
  else
    printf "999999\t%s\n" "$1"
  fi
}

sort_key_for_chapter() {
  local name
  name="$(basename "$1" .md)"

  if [[ "$name" =~ ^Week[[:space:]]+([0-9]+) ]]; then
    printf "%06d\t%s\n" "${BASH_REMATCH[1]}" "$1"
  else
    printf "999999\t%s\n" "$1"
  fi
}

strip_first_markdown_heading() {
  awk '
    NR == 1 && /^#[[:space:]]+/ { skip_leading_blank = 1; next }
    skip_leading_blank && NR == 2 && /^[[:space:]]*$/ { skip_leading_blank = 0; next }
    { skip_leading_blank = 0; print }
  ' "$1"
}

{
  printf "# %s\n\n" "$BOOK_TITLE"
  printf "%s\n" "$AUTHOR"

  while IFS=$'\t' read -r _ phase_dir; do
    [[ -n "$phase_dir" ]] || continue

    phase_title="$(basename "$phase_dir")"
    printf "\n## %s\n" "$phase_title"

    while IFS=$'\t' read -r _ chapter_file; do
      [[ -n "$chapter_file" ]] || continue

      chapter_title="$(basename "$chapter_file" .md)"
      printf "\n### %s\n\n" "$chapter_title"
      strip_first_markdown_heading "$chapter_file"
      printf "\n"
    done < <(
      find "$phase_dir" -maxdepth 1 -type f -name '*.md' -print |
        while IFS= read -r chapter_file; do
          sort_key_for_chapter "$chapter_file"
        done |
        sort -k1,1n -k2,2
    )
  done < <(
    find "$CHAPTERS_DIR" -mindepth 1 -maxdepth 1 -type d -print |
      while IFS= read -r phase_dir; do
        sort_key_for_phase "$phase_dir"
      done |
      sort -k1,1n -k2,2
  )
} > "$OUTPUT_FILE"

echo "Generated $OUTPUT_FILE"
