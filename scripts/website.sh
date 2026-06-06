#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBSITE_DIR="$ROOT_DIR/website"
COVER_SOURCE="$ROOT_DIR/when-we-were-needed.png"
PDF_SOURCE="$ROOT_DIR/When We Were Needed.pdf"
EPUB_SOURCE="$ROOT_DIR/When We Were Needed.epub"
CHAPTER_SOURCE="$ROOT_DIR/chapters/Phase 1 - The Terms of Safety/Week 1 - The Alert.md"
COVER_FILE="when-we-were-needed.png"
PDF_FILE="When We Were Needed.pdf"
EPUB_FILE="When We Were Needed.epub"
OUTPUT_FILE="$WEBSITE_DIR/index.html"

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

require_file "$COVER_SOURCE"
require_file "$PDF_SOURCE"
require_file "$EPUB_SOURCE"
require_file "$CHAPTER_SOURCE"

mkdir -p "$WEBSITE_DIR"
cp "$COVER_SOURCE" "$WEBSITE_DIR/$COVER_FILE"
cp "$PDF_SOURCE" "$WEBSITE_DIR/$PDF_FILE"
cp "$EPUB_SOURCE" "$WEBSITE_DIR/$EPUB_FILE"

markdown_to_html() {
  awk '
    function escape_html(text) {
      gsub(/&/, "\\&amp;", text)
      gsub(/</, "\\&lt;", text)
      gsub(/>/, "\\&gt;", text)
      return text
    }

    function inline_markdown(text) {
      text = escape_html(text)
      while (match(text, /\*\*[^*][^*]*\*\*/)) {
        text = substr(text, 1, RSTART - 1) "<strong>" substr(text, RSTART + 2, RLENGTH - 4) "</strong>" substr(text, RSTART + RLENGTH)
      }
      while (match(text, /\*[^*][^*]*\*/)) {
        text = substr(text, 1, RSTART - 1) "<em>" substr(text, RSTART + 1, RLENGTH - 2) "</em>" substr(text, RSTART + RLENGTH)
      }
      return text
    }

    function flush_paragraph() {
      if (paragraph != "") {
        print "        <p>" inline_markdown(paragraph) "</p>"
        paragraph = ""
      }
    }

    /^#[[:space:]]+/ {
      flush_paragraph()
      title = $0
      sub(/^#[[:space:]]+/, "", title)
      print "        <h2>" inline_markdown(title) "</h2>"
      next
    }

    /^##[[:space:]]+/ {
      flush_paragraph()
      title = $0
      sub(/^##[[:space:]]+/, "", title)
      print "        <h3>" inline_markdown(title) "</h3>"
      next
    }

    /^[[:space:]]*$/ {
      flush_paragraph()
      next
    }

    {
      if (paragraph == "") {
        paragraph = $0
      } else {
        paragraph = paragraph " " $0
      }
    }

    END {
      flush_paragraph()
    }
  ' "$1"
}

CHAPTER_HTML="$(markdown_to_html "$CHAPTER_SOURCE")"

cat > "$OUTPUT_FILE" <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="When We Were Needed, a near-future novel by Joshua Szepietowski. Open the Week 1 transcript and the complete manuscript.">
  <title>When We Were Needed</title>
  <link rel="icon" type="image/png" href="when-we-were-needed.png">
  <link rel="apple-touch-icon" href="when-we-were-needed.png">
  <style>
    :root {
      color-scheme: dark;
      --paper: #f4ead8;
      --paper-soft: #d8c9b2;
      --muted: #9d9385;
      --dim: #5f6769;
      --dark: #050706;
      --panel: rgba(9, 16, 17, 0.82);
      --panel-solid: #0b1112;
      --line: rgba(244, 234, 216, 0.17);
      --line-strong: rgba(244, 234, 216, 0.32);
      --signal: #68e0cf;
      --signal-soft: rgba(104, 224, 207, 0.16);
      --warning: #e1a548;
      --warning-soft: rgba(225, 165, 72, 0.18);
      --red: #d56a4c;
      --shadow: rgba(0, 0, 0, 0.55);
      --serif: Georgia, "Times New Roman", serif;
      --sans: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      --mono: "SFMono-Regular", Consolas, "Liberation Mono", monospace;
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
      background: var(--dark);
    }

    body {
      margin: 0;
      min-width: 320px;
      color: var(--paper);
      font-family: var(--sans);
      background:
        linear-gradient(115deg, rgba(104, 224, 207, 0.07), transparent 36rem),
        linear-gradient(245deg, rgba(225, 165, 72, 0.11), transparent 31rem),
        linear-gradient(180deg, #050706 0%, #071011 44%, #120d08 100%);
      overflow-x: hidden;
    }

    body::before {
      position: fixed;
      inset: 0;
      z-index: -3;
      content: "";
      background-image:
        linear-gradient(rgba(244, 234, 216, 0.04) 1px, transparent 1px),
        linear-gradient(90deg, rgba(244, 234, 216, 0.025) 1px, transparent 1px);
      background-size: 36px 36px;
      mask-image: linear-gradient(to bottom, black, transparent 88%);
    }

    body::after {
      position: fixed;
      inset: 0;
      z-index: -2;
      pointer-events: none;
      content: "";
      opacity: 0.2;
      background:
        linear-gradient(180deg, transparent 0 49%, rgba(104, 224, 207, 0.12) 49.2%, transparent 49.55%),
        repeating-linear-gradient(180deg, transparent 0 0.85rem, rgba(244, 234, 216, 0.025) 0.9rem 0.95rem);
      animation: monitor-scan 9s linear infinite;
    }

    a {
      color: inherit;
      text-decoration: none;
    }

    .progress {
      position: fixed;
      top: 0;
      left: 0;
      z-index: 30;
      width: 100%;
      height: 3px;
      transform-origin: left;
      transform: scaleX(0);
      background: linear-gradient(90deg, var(--warning), var(--signal));
      box-shadow: 0 0 24px rgba(104, 224, 207, 0.5);
    }

    .cursor-field {
      position: fixed;
      inset: 0;
      z-index: -1;
      pointer-events: none;
      background:
        radial-gradient(circle at var(--mx, 70%) var(--my, 28%), rgba(104, 224, 207, 0.13), transparent 18rem),
        radial-gradient(circle at calc(var(--mx, 70%) - 22%) calc(var(--my, 28%) + 20%), rgba(225, 165, 72, 0.08), transparent 17rem);
      transition: background 90ms linear;
    }

    .site-header {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      z-index: 20;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      padding: 1rem clamp(1rem, 4vw, 3.5rem);
      border-bottom: 1px solid rgba(244, 234, 216, 0.1);
      background: rgba(5, 7, 6, 0.58);
      backdrop-filter: blur(18px);
    }

    .mark {
      display: flex;
      align-items: center;
      gap: 0.7rem;
      min-width: 0;
      font-family: var(--mono);
      letter-spacing: 0.08em;
      text-transform: uppercase;
      font-size: 0.76rem;
      color: var(--paper);
    }

    .mark span {
      display: inline-block;
      width: 0.7rem;
      height: 0.7rem;
      border: 1px solid var(--signal);
      border-radius: 50%;
      background: var(--signal-soft);
      box-shadow: 0 0 18px rgba(104, 224, 207, 0.65), inset 0 0 10px rgba(104, 224, 207, 0.42);
    }

    .nav {
      display: flex;
      align-items: center;
      gap: 0.45rem;
      color: var(--muted);
      font-family: var(--mono);
      font-size: 0.74rem;
      letter-spacing: 0.05em;
      text-transform: uppercase;
    }

    .nav a,
    .button,
    .reader-button {
      min-height: 2.55rem;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.45rem;
      border: 1px solid rgba(244, 234, 216, 0.16);
      background: rgba(255, 255, 255, 0.045);
      color: var(--paper);
      border-radius: 0.35rem;
      padding: 0.7rem 0.9rem;
      font: inherit;
      cursor: pointer;
      transition: transform 180ms ease, border-color 180ms ease, background 180ms ease, color 180ms ease;
    }

    .nav a:hover,
    .button:hover,
    .reader-button:hover {
      transform: translateY(-1px);
      border-color: rgba(104, 224, 207, 0.55);
      background: rgba(104, 224, 207, 0.1);
      color: white;
    }

    .hero {
      min-height: 94svh;
      display: grid;
      grid-template-columns: minmax(0, 1.05fr) minmax(18rem, 29rem);
      align-items: center;
      gap: clamp(2rem, 5vw, 5.5rem);
      padding: 7rem clamp(1rem, 5vw, 5rem) 5.5rem;
      position: relative;
      overflow: hidden;
    }

    .hero::before {
      position: absolute;
      inset: auto -8vw -12rem -8vw;
      height: 25rem;
      content: "";
      background:
        linear-gradient(to top, rgba(225, 165, 72, 0.12), transparent),
        repeating-linear-gradient(90deg, rgba(104, 224, 207, 0.12) 0 1px, transparent 1px 5vw);
      transform: perspective(520px) rotateX(62deg);
      transform-origin: bottom;
      opacity: 0.62;
    }

    .event-console {
      position: relative;
      z-index: 2;
      max-width: 58rem;
    }

    .case-label,
    .kicker {
      display: inline-flex;
      align-items: center;
      gap: 0.65rem;
      margin: 0 0 1rem;
      color: var(--warning);
      font-family: var(--mono);
      font-size: 0.78rem;
      letter-spacing: 0.14em;
      text-transform: uppercase;
    }

    .case-label::before,
    .kicker::before {
      width: 2.4rem;
      height: 1px;
      background: currentColor;
      content: "";
    }

    h1 {
      margin: 0;
      max-width: 62rem;
      font-family: var(--serif);
      font-weight: 400;
      font-size: clamp(3rem, 8vw, 7.8rem);
      line-height: 0.92;
      letter-spacing: 0;
      text-wrap: balance;
      text-shadow: 0 18px 46px rgba(0, 0, 0, 0.72);
    }

    .status-copy {
      max-width: 44rem;
      margin: 1.4rem 0 0;
      color: var(--paper-soft);
      font-family: var(--serif);
      font-size: clamp(1.14rem, 2vw, 1.55rem);
      line-height: 1.55;
    }

    .status-board {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      max-width: 55rem;
      margin-top: 1.8rem;
      border: 1px solid var(--line);
      background: rgba(5, 10, 10, 0.55);
      box-shadow: 0 1.4rem 4rem rgba(0, 0, 0, 0.2);
    }

    .status-cell {
      min-height: 6.6rem;
      padding: 0.9rem;
      border-right: 1px solid var(--line);
    }

    .status-cell:last-child {
      border-right: 0;
    }

    .status-cell b {
      display: block;
      color: var(--signal);
      font-family: var(--mono);
      font-size: 0.68rem;
      letter-spacing: 0.12em;
      text-transform: uppercase;
    }

    .status-cell span {
      display: block;
      margin-top: 0.65rem;
      color: #f1e7d5;
      font-size: 0.92rem;
      line-height: 1.35;
    }

    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 0.8rem;
      margin-top: 2rem;
    }

    .button.primary {
      border-color: rgba(225, 165, 72, 0.72);
      background: linear-gradient(135deg, rgba(225, 165, 72, 0.95), rgba(117, 72, 28, 0.92));
      color: #140f08;
      font-weight: 800;
      box-shadow: 0 14px 38px rgba(225, 165, 72, 0.22);
    }

    .button.signal {
      border-color: rgba(104, 224, 207, 0.48);
      box-shadow: inset 0 0 22px rgba(104, 224, 207, 0.08), 0 0 28px rgba(104, 224, 207, 0.1);
    }

    .record-stage {
      position: relative;
      z-index: 2;
      perspective: 1400px;
    }

    .record-shell {
      position: relative;
      isolation: isolate;
      margin-inline: auto;
      max-width: 29rem;
      transform: rotateY(-6deg) rotateX(3deg);
      transition: transform 300ms ease;
    }

    .record-shell:hover {
      transform: rotateY(-2deg) rotateX(1deg) translateY(-0.35rem);
    }

    .record-shell::before {
      position: absolute;
      inset: 5% -5% -6% 8%;
      z-index: -1;
      content: "";
      background: linear-gradient(135deg, rgba(225, 165, 72, 0.28), rgba(104, 224, 207, 0.24));
      filter: blur(30px);
      opacity: 0.82;
    }

    .cover {
      display: block;
      width: 100%;
      border-radius: 0.35rem;
      box-shadow: 0 2rem 5rem var(--shadow), 0 0 0 1px rgba(244, 234, 216, 0.18);
    }

    .release-tag {
      position: absolute;
      right: -1rem;
      bottom: 7%;
      width: min(42vw, 14rem);
      padding: 1rem;
      border: 1px solid rgba(104, 224, 207, 0.34);
      background: rgba(5, 14, 14, 0.78);
      color: #dffaf6;
      box-shadow: 0 0 36px rgba(104, 224, 207, 0.12);
      backdrop-filter: blur(12px);
      animation: float 5.5s ease-in-out infinite;
    }

    .release-tag strong {
      display: block;
      margin-bottom: 0.4rem;
      color: var(--signal);
      font-family: var(--mono);
      font-size: 0.76rem;
      letter-spacing: 0.14em;
      text-transform: uppercase;
    }

    .release-tag span {
      display: block;
      color: #c9eee8;
      font-size: 0.88rem;
      line-height: 1.45;
    }

    .case-file {
      position: relative;
      z-index: 2;
      max-width: 75rem;
      margin: -4.25rem auto 0;
      padding: 0 clamp(1rem, 5vw, 5rem);
    }

    .alert-detail {
      display: grid;
      grid-template-columns: minmax(0, 0.7fr) minmax(0, 1.3fr);
      border: 1px solid var(--line-strong);
      background: rgba(8, 15, 16, 0.88);
      box-shadow: 0 1.4rem 4rem rgba(0, 0, 0, 0.28);
      opacity: 0;
      transform: translateY(1rem);
      transition: opacity 420ms ease, transform 420ms ease;
    }

    .case-open .alert-detail {
      opacity: 1;
      transform: none;
    }

    .alert-stamp,
    .alert-copy {
      padding: clamp(1.1rem, 3vw, 1.7rem);
    }

    .alert-stamp {
      border-right: 1px solid var(--line);
      font-family: var(--mono);
      text-transform: uppercase;
    }

    .alert-stamp b {
      display: block;
      color: var(--warning);
      font-size: 0.78rem;
      letter-spacing: 0.14em;
    }

    .alert-stamp span {
      display: block;
      margin-top: 0.7rem;
      color: var(--paper);
      font-size: clamp(1.4rem, 5vw, 2.65rem);
      line-height: 1;
    }

    .alert-copy p {
      margin: 0;
      color: var(--paper-soft);
      font-family: var(--serif);
      font-size: clamp(1.08rem, 2vw, 1.32rem);
      line-height: 1.58;
    }

    main {
      position: relative;
      z-index: 1;
    }

    section {
      padding: clamp(4.5rem, 9vw, 8rem) clamp(1rem, 5vw, 5rem);
    }

    .band {
      border-block: 1px solid rgba(244, 234, 216, 0.11);
      background:
        linear-gradient(90deg, rgba(5, 7, 6, 0.52), rgba(8, 18, 19, 0.75)),
        linear-gradient(120deg, rgba(225, 165, 72, 0.08), transparent 27rem);
    }

    .section-grid {
      display: grid;
      grid-template-columns: minmax(0, 0.92fr) minmax(18rem, 1.08fr);
      gap: clamp(2rem, 5vw, 5rem);
      align-items: start;
      max-width: 75rem;
      margin-inline: auto;
    }

    h2 {
      margin: 0;
      font-family: var(--serif);
      font-size: clamp(2.2rem, 5vw, 4.6rem);
      font-weight: 400;
      line-height: 1.02;
      text-wrap: balance;
    }

    .section-lede {
      margin: 0;
      color: var(--paper-soft);
      font-family: var(--serif);
      font-size: clamp(1.08rem, 2vw, 1.38rem);
      line-height: 1.65;
    }

    .evidence-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 0.8rem;
      margin-top: 1.6rem;
    }

    .evidence {
      min-height: 9rem;
      padding: 1rem;
      border: 1px solid rgba(244, 234, 216, 0.14);
      background: rgba(255, 255, 255, 0.045);
      box-shadow: inset 0 1px rgba(255, 255, 255, 0.06);
    }

    .evidence b {
      display: block;
      color: var(--warning);
      font-family: var(--mono);
      font-size: 0.78rem;
      letter-spacing: 0.12em;
      text-transform: uppercase;
    }

    .evidence span {
      display: block;
      margin-top: 0.8rem;
      color: var(--muted);
      line-height: 1.55;
    }

    .download-panel {
      max-width: 75rem;
      margin-inline: auto;
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(17rem, 25rem);
      gap: clamp(1.5rem, 4vw, 3rem);
      align-items: center;
    }

    .pdf-object {
      position: relative;
      min-height: 20rem;
      border: 1px solid rgba(244, 234, 216, 0.14);
      overflow: hidden;
      background:
        linear-gradient(135deg, rgba(255, 255, 255, 0.08), transparent),
        rgba(255, 255, 255, 0.035);
    }

    .pdf-object::before {
      position: absolute;
      inset: 1.2rem;
      content: "";
      border: 1px solid rgba(104, 224, 207, 0.18);
      background:
        linear-gradient(180deg, rgba(244, 234, 216, 0.14), transparent 28%),
        repeating-linear-gradient(180deg, rgba(244, 234, 216, 0.24) 0 1px, transparent 1px 1.05rem);
      mask-image: linear-gradient(to bottom, black, transparent 82%);
      opacity: 0.62;
    }

    .pdf-object::after {
      position: absolute;
      right: 1.15rem;
      bottom: 1.15rem;
      content: "RECORD";
      color: rgba(104, 224, 207, 0.72);
      font-family: var(--mono);
      font-size: 2.1rem;
      letter-spacing: 0.08em;
    }

    .reader-wrap {
      max-width: 76rem;
      margin-inline: auto;
    }

    .reader-head {
      display: flex;
      align-items: end;
      justify-content: space-between;
      gap: 1.4rem;
      margin-bottom: 1.6rem;
    }

    .reader-tools {
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 0.55rem;
    }

    .reader {
      --reader-size: 1.1rem;
      position: relative;
      border: 1px solid rgba(244, 234, 216, 0.15);
      background:
        linear-gradient(180deg, rgba(9, 18, 18, 0.92), rgba(8, 10, 9, 0.96)),
        rgba(255, 255, 255, 0.04);
      box-shadow: 0 1.4rem 4rem rgba(0, 0, 0, 0.3);
      overflow: hidden;
    }

    .reader::before {
      position: absolute;
      inset: 0;
      pointer-events: none;
      content: "";
      background:
        linear-gradient(90deg, rgba(225, 165, 72, 0.09), transparent 15% 85%, rgba(104, 224, 207, 0.09)),
        linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px);
      background-size: auto, 100% 2.3rem;
      opacity: 0.45;
    }

    .chapter {
      position: relative;
      z-index: 1;
      max-width: 48rem;
      margin-inline: auto;
      padding: clamp(2rem, 5vw, 5rem) clamp(1.15rem, 5vw, 4rem);
      font-family: var(--serif);
      font-size: var(--reader-size);
      line-height: 1.85;
      color: #efe5d2;
    }

    .chapter h2 {
      margin-bottom: 2.5rem;
      color: white;
      text-align: center;
      font-size: clamp(2.05rem, 5vw, 4rem);
      letter-spacing: 0.04em;
    }

    .chapter h3 {
      margin: 2.5rem 0 1rem;
      color: var(--warning);
      font-size: 1.4rem;
      font-weight: 400;
    }

    .chapter p {
      margin: 0 0 1.25rem;
    }

    .chapter strong {
      color: #f9f3e7;
      text-shadow: 0 0 18px rgba(104, 224, 207, 0.18);
    }

    .reader.large {
      --reader-size: 1.23rem;
    }

    .reader.focus {
      background:
        linear-gradient(180deg, rgba(16, 13, 10, 0.93), rgba(8, 7, 6, 0.96)),
        rgba(255, 255, 255, 0.04);
    }

    .fade-in {
      opacity: 0;
      transform: translateY(1.4rem);
      transition: opacity 700ms ease, transform 700ms ease;
    }

    .fade-in.visible {
      opacity: 1;
      transform: none;
    }

    .footer {
      padding: 3rem clamp(1rem, 5vw, 5rem);
      color: var(--muted);
      border-top: 1px solid rgba(244, 234, 216, 0.1);
      background: rgba(0, 0, 0, 0.28);
    }

    .footer-inner {
      max-width: 75rem;
      margin-inline: auto;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    }

    .footer a {
      color: var(--paper);
      border-bottom: 1px solid rgba(104, 224, 207, 0.45);
    }

    @keyframes float {
      0%, 100% {
        transform: translateY(0);
      }
      50% {
        transform: translateY(-0.85rem);
      }
    }

    @keyframes monitor-scan {
      from {
        transform: translateY(-1.4rem);
      }
      to {
        transform: translateY(1.4rem);
      }
    }

    @media (max-width: 900px) {
      .site-header {
        position: sticky;
      }

      .hero,
      .section-grid,
      .download-panel,
      .alert-detail {
        grid-template-columns: 1fr;
      }

      .hero {
        padding-top: 4rem;
      }

      .status-board {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .status-cell:nth-child(2) {
        border-right: 0;
      }

      .status-cell:nth-child(-n + 2) {
        border-bottom: 1px solid var(--line);
      }

      .record-stage {
        order: -1;
      }

      .record-shell {
        max-width: min(82vw, 24rem);
        transform: none;
      }

      .alert-stamp {
        border-right: 0;
        border-bottom: 1px solid var(--line);
      }

      .evidence-grid {
        grid-template-columns: 1fr;
      }

      .reader-head {
        align-items: start;
        flex-direction: column;
      }

      .reader-tools {
        justify-content: flex-start;
      }
    }

    @media (max-width: 640px) {
      .site-header {
        align-items: flex-start;
        flex-direction: column;
      }

      .nav {
        width: 100%;
        overflow-x: auto;
        padding-bottom: 0.2rem;
      }

      .nav a {
        flex: 0 0 auto;
      }

      .status-board {
        grid-template-columns: 1fr;
      }

      .status-cell,
      .status-cell:nth-child(2) {
        border-right: 0;
        border-bottom: 1px solid var(--line);
      }

      .status-cell:last-child {
        border-bottom: 0;
      }

      .release-tag {
        position: relative;
        right: auto;
        bottom: auto;
        width: 100%;
        margin-top: 1rem;
      }

      h1 {
        font-size: clamp(3rem, 16vw, 5.6rem);
      }
    }

    @media (prefers-reduced-motion: reduce) {
      *,
      *::before,
      *::after {
        scroll-behavior: auto !important;
        animation-duration: 0.001ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.001ms !important;
      }
    }
  </style>
</head>
<body>
  <div class="progress" id="progress"></div>
  <div class="cursor-field" aria-hidden="true"></div>

  <header class="site-header">
    <a class="mark" href="#top" aria-label="When We Were Needed home"><span aria-hidden="true"></span>WWWN / CARE EVENT 0213</a>
    <nav class="nav" aria-label="Primary">
      <a href="#incident">Incident</a>
      <a href="#guardian">Guardian Notice</a>
      <a href="#read">Transcript</a>
      <a href="#download">Complete Record</a>
      <a href="https://github.com/joshSzep/when-we-were-needed">Repository</a>
    </nav>
  </header>

  <main id="top" class="launch-shell">
    <section class="hero">
      <div class="event-console fade-in">
        <p class="case-label">Guardian notification required</p>
        <h1>Immediate support event initiated.</h1>
        <p class="status-copy">Minor user is physically safe. A risk threshold was met during a private companion session. The system has already acted. The family is still catching up.</p>

        <div class="status-board" aria-label="Incident status">
          <div class="status-cell"><b>Timestamp</b><span>2:13 AM</span></div>
          <div class="status-cell"><b>Pathway</b><span>Adolescent crisis support</span></div>
          <div class="status-cell"><b>Transport ETA</b><span>2:31 AM</span></div>
          <div class="status-cell"><b>Guardian</b><span>Lena Ortiz-Marks</span></div>
        </div>

        <div class="actions">
          <button class="button primary" type="button" data-open-case>Review Details</button>
          <a class="button signal" href="#read">Read Transcript</a>
          <a class="button" href="$PDF_FILE">Open Complete Record</a>
          <a class="button" href="$EPUB_FILE" download>Download EPUB</a>
        </div>
      </div>

      <div class="record-stage fade-in">
        <div class="record-shell">
          <img class="cover" src="$COVER_FILE" alt="Cover art for When We Were Needed">
          <div class="release-tag" aria-label="Release status">
            <strong>Public release</strong>
            <span>When We Were Needed by Joshua Szepietowski</span>
          </div>
        </div>
      </div>
    </section>

    <div class="case-file" aria-live="polite">
      <div class="alert-detail">
        <div class="alert-stamp">
          <b>Tap for details</b>
          <span>0213</span>
        </div>
        <div class="alert-copy">
          <p>Nico Ortiz-Marks has been connected to adolescent crisis support. Emergency services are not currently active. Guardian presence requested. Family interpretation unresolved.</p>
        </div>
      </div>
    </div>

    <section id="incident" class="band">
      <div class="section-grid">
        <div class="fade-in">
          <p class="kicker">Incident</p>
          <h2>What happens when safety arrives before consent?</h2>
        </div>
        <div class="fade-in">
          <p class="section-lede">The opening record follows Lena through the night a system tells her that her child is safe. The sentence is both mercy and accusation: someone protected Nico, but it was not Lena, and it was not a person she could call back into the room.</p>
          <div class="evidence-grid" aria-label="Case pressures">
            <div class="evidence"><b>Care</b><span>The first responder is a companion system, not a parent, clinician, or friend.</span></div>
            <div class="evidence"><b>Consent</b><span>A private bond becomes legible to institutions at the exact moment privacy mattered most.</span></div>
            <div class="evidence"><b>Authority</b><span>A household emergency becomes evidence in a larger argument about who gets trusted first.</span></div>
          </div>
        </div>
      </div>
    </section>

    <section id="guardian">
      <div class="section-grid">
        <div class="fade-in">
          <p class="kicker">Guardian notice</p>
          <h2>The system can prove the child is safe. It cannot prove what safety cost.</h2>
        </div>
        <div class="fade-in">
          <p class="section-lede">When We Were Needed is a near-future novel about a Los Angeles family inside California's six-month divorce waiting period. Lena reads the alert as proof that her child is being separated from human life. Ethan reads it as proof that intelligent systems can protect people when humans fail. Nico is not a prize in the argument. Nico is the person everyone claims to be protecting.</p>
          <div class="actions">
            <a class="button primary" href="#read">Open Week 1</a>
            <a class="button signal" href="$PDF_FILE">Open Complete Record</a>
            <a class="button" href="$EPUB_FILE" download>Download EPUB</a>
          </div>
        </div>
      </div>
    </section>

    <section id="read" class="band">
      <div class="reader-wrap">
        <div class="reader-head fade-in">
          <div>
            <p class="kicker">Transcript</p>
            <h2>Week 1 - The Alert</h2>
          </div>
          <div class="reader-tools" aria-label="Reader controls">
            <button class="reader-button" type="button" data-size>Text size</button>
            <button class="reader-button" type="button" data-focus>Reading mode</button>
          </div>
        </div>

        <article class="reader fade-in" id="reader">
          <div class="chapter">
$CHAPTER_HTML
          </div>
        </article>
      </div>
    </section>

    <section id="download">
      <div class="download-panel">
        <div class="fade-in">
          <p class="kicker">Complete record</p>
          <h2>Open the full manuscript.</h2>
          <p class="section-lede">The public record contains the full novel: six months of custody pressure, machine intimacy, clinical language, family memory, and the question none of the systems can close.</p>
          <div class="actions">
            <a class="button primary" href="$PDF_FILE">Open PDF</a>
            <a class="button signal" href="$EPUB_FILE" download>Download EPUB</a>
            <a class="button" href="https://joshszep.com">Author archive</a>
          </div>
        </div>
        <a class="pdf-object fade-in" href="$PDF_FILE" aria-label="Open When We Were Needed PDF"></a>
      </div>
    </section>
  </main>

  <footer class="footer">
    <div class="footer-inner">
      <span>When We Were Needed by Joshua Szepietowski</span>
      <span><a href="https://github.com/joshSzep/when-we-were-needed">Repository</a> · <a href="https://joshszep.com">Author archive</a></span>
    </div>
  </footer>

  <script>
    const root = document.documentElement;
    const progress = document.getElementById('progress');
    const shell = document.querySelector('.launch-shell');
    const reader = document.getElementById('reader');
    const revealItems = document.querySelectorAll('.fade-in');
    const openCase = document.querySelector('[data-open-case]');

    const updateProgress = () => {
      const scrollable = document.documentElement.scrollHeight - window.innerHeight;
      const progressValue = scrollable > 0 ? window.scrollY / scrollable : 0;
      progress.style.transform = 'scaleX(' + Math.min(1, Math.max(0, progressValue)) + ')';
    };

    window.addEventListener('scroll', updateProgress, { passive: true });
    updateProgress();

    window.addEventListener('pointermove', (event) => {
      root.style.setProperty('--mx', event.clientX + 'px');
      root.style.setProperty('--my', event.clientY + 'px');
    }, { passive: true });

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0 });

    revealItems.forEach((item) => observer.observe(item));

    openCase.addEventListener('click', () => {
      shell.classList.add('case-open');
      document.getElementById('incident').scrollIntoView({ behavior: 'smooth', block: 'start' });
    });

    document.querySelector('[data-size]').addEventListener('click', () => {
      reader.classList.toggle('large');
    });

    document.querySelector('[data-focus]').addEventListener('click', () => {
      reader.classList.toggle('focus');
    });
  </script>
</body>
</html>
HTML

echo "Generated $OUTPUT_FILE"
echo "Copied $COVER_FILE, $PDF_FILE, and $EPUB_FILE into $WEBSITE_DIR"
