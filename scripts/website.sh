#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEBSITE_DIR="$ROOT_DIR/website"
COVER_SOURCE="$ROOT_DIR/when-we-were-needed.png"
PDF_SOURCE="$ROOT_DIR/When We Were Needed.pdf"
CHAPTER_SOURCE="$ROOT_DIR/chapters/Phase 1 - The Terms of Safety/Week 1 - The Alert.md"
COVER_FILE="when-we-were-needed.png"
PDF_FILE="When We Were Needed.pdf"
OUTPUT_FILE="$WEBSITE_DIR/index.html"

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

require_file "$COVER_SOURCE"
require_file "$PDF_SOURCE"
require_file "$CHAPTER_SOURCE"

mkdir -p "$WEBSITE_DIR"
cp "$COVER_SOURCE" "$WEBSITE_DIR/$COVER_FILE"
cp "$PDF_SOURCE" "$WEBSITE_DIR/$PDF_FILE"

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
  <meta name="description" content="When We Were Needed, a novel by Joshua Szepietowski. Read Week 1 and download the full novel for free.">
  <title>When We Were Needed</title>
  <style>
    :root {
      color-scheme: dark;
      --ink: #f3ead9;
      --muted: #b8ad9b;
      --dim: #756d64;
      --night: #05070a;
      --midnight: #08121c;
      --glass: rgba(7, 13, 19, 0.7);
      --line: rgba(243, 234, 217, 0.18);
      --amber: #d88a32;
      --amber-soft: #f1c47d;
      --cyan: #5fd6ff;
      --cyan-deep: #08759d;
      --danger: #cc6239;
      --shadow: rgba(0, 0, 0, 0.54);
      --serif: Georgia, "Times New Roman", serif;
      --sans: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    * {
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
      background: var(--night);
    }

    body {
      margin: 0;
      min-width: 320px;
      color: var(--ink);
      font-family: var(--sans);
      background:
        radial-gradient(circle at 78% 18%, rgba(95, 214, 255, 0.2), transparent 26rem),
        radial-gradient(circle at 17% 36%, rgba(216, 138, 50, 0.2), transparent 24rem),
        linear-gradient(135deg, #030507 0%, #08121c 48%, #160d09 100%);
      overflow-x: hidden;
    }

    body::before {
      position: fixed;
      inset: 0;
      z-index: -3;
      content: "";
      background-image:
        linear-gradient(rgba(255, 255, 255, 0.025) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255, 255, 255, 0.018) 1px, transparent 1px);
      background-size: 44px 44px;
      mask-image: linear-gradient(to bottom, black, transparent 86%);
    }

    body::after {
      position: fixed;
      inset: 0;
      z-index: -2;
      pointer-events: none;
      content: "";
      opacity: 0.28;
      background:
        linear-gradient(115deg, transparent 0 42%, rgba(95, 214, 255, 0.18) 42.2%, transparent 42.9%),
        linear-gradient(70deg, transparent 0 54%, rgba(216, 138, 50, 0.16) 54.2%, transparent 54.9%);
      animation: scan 14s linear infinite;
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
      background: linear-gradient(90deg, var(--amber), var(--cyan));
      box-shadow: 0 0 24px rgba(95, 214, 255, 0.7);
    }

    .aurora {
      position: fixed;
      inset: 0;
      z-index: -1;
      pointer-events: none;
      background:
        radial-gradient(circle at var(--mx, 70%) var(--my, 30%), rgba(95, 214, 255, 0.18), transparent 21rem),
        radial-gradient(circle at calc(var(--mx, 70%) - 28%) calc(var(--my, 30%) + 22%), rgba(216, 138, 50, 0.12), transparent 18rem);
      transition: background 0.08s linear;
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
      border-bottom: 1px solid rgba(243, 234, 217, 0.08);
      background: rgba(5, 7, 10, 0.38);
      backdrop-filter: blur(18px);
    }

    .mark {
      display: flex;
      align-items: center;
      gap: 0.7rem;
      min-width: 0;
      font-family: var(--serif);
      letter-spacing: 0.12em;
      text-transform: uppercase;
      font-size: 0.76rem;
      color: var(--ink);
    }

    .mark span {
      display: inline-block;
      width: 0.68rem;
      height: 0.68rem;
      border: 1px solid rgba(95, 214, 255, 0.86);
      border-radius: 50%;
      box-shadow: 0 0 18px rgba(95, 214, 255, 0.78), inset 0 0 9px rgba(95, 214, 255, 0.7);
    }

    .nav {
      display: flex;
      align-items: center;
      gap: 0.45rem;
      color: var(--muted);
      font-size: 0.9rem;
    }

    .nav a,
    .button,
    .reader-button {
      min-height: 2.55rem;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.45rem;
      border: 1px solid rgba(243, 234, 217, 0.16);
      background: rgba(255, 255, 255, 0.045);
      color: var(--ink);
      border-radius: 0.45rem;
      padding: 0.7rem 0.9rem;
      font: inherit;
      cursor: pointer;
      transition: transform 180ms ease, border-color 180ms ease, background 180ms ease, color 180ms ease;
    }

    .nav a:hover,
    .button:hover,
    .reader-button:hover {
      transform: translateY(-1px);
      border-color: rgba(95, 214, 255, 0.5);
      background: rgba(95, 214, 255, 0.1);
      color: white;
    }

    .hero {
      min-height: 100svh;
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(19rem, 31rem);
      align-items: center;
      gap: clamp(2rem, 6vw, 6rem);
      padding: 7.5rem clamp(1rem, 5vw, 5rem) 4rem;
      position: relative;
      overflow: hidden;
    }

    .hero::before {
      position: absolute;
      inset: auto -10vw -14rem -10vw;
      height: 29rem;
      content: "";
      background:
        linear-gradient(to top, rgba(216, 138, 50, 0.16), transparent),
        repeating-linear-gradient(90deg, rgba(241, 196, 125, 0.12) 0 1px, transparent 1px 4.7vw);
      transform: perspective(500px) rotateX(61deg);
      transform-origin: bottom;
      opacity: 0.72;
    }

    .hero-copy {
      position: relative;
      z-index: 2;
      max-width: 58rem;
    }

    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 0.65rem;
      margin: 0 0 1.2rem;
      color: var(--amber-soft);
      font-size: 0.78rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
    }

    .eyebrow::before {
      width: 2.4rem;
      height: 1px;
      background: currentColor;
      content: "";
    }

    h1 {
      margin: 0;
      font-family: var(--serif);
      font-weight: 400;
      font-size: clamp(3.1rem, 10vw, 9.6rem);
      line-height: 0.88;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      text-wrap: balance;
      text-shadow: 0 18px 46px rgba(0, 0, 0, 0.72);
    }

    .dek {
      max-width: 42rem;
      margin: 1.55rem 0 0;
      color: #d7ccbb;
      font-family: var(--serif);
      font-size: clamp(1.15rem, 2.1vw, 1.65rem);
      line-height: 1.55;
    }

    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 0.8rem;
      margin-top: 2rem;
    }

    .button.primary {
      border-color: rgba(216, 138, 50, 0.62);
      background: linear-gradient(135deg, rgba(216, 138, 50, 0.95), rgba(121, 58, 30, 0.92));
      color: #130b07;
      font-weight: 800;
      box-shadow: 0 14px 38px rgba(216, 138, 50, 0.24);
    }

    .button.cyan {
      border-color: rgba(95, 214, 255, 0.48);
      box-shadow: inset 0 0 22px rgba(95, 214, 255, 0.08), 0 0 28px rgba(95, 214, 255, 0.12);
    }

    .cover-stage {
      position: relative;
      z-index: 2;
      perspective: 1400px;
    }

    .cover-shell {
      position: relative;
      isolation: isolate;
      margin-inline: auto;
      max-width: 29rem;
      transform: rotateY(-7deg) rotateX(4deg);
      transition: transform 300ms ease;
    }

    .cover-shell:hover {
      transform: rotateY(-2deg) rotateX(1deg) translateY(-0.4rem);
    }

    .cover-shell::before {
      position: absolute;
      inset: 4% -5% -6% 7%;
      z-index: -1;
      content: "";
      border-radius: 1.2rem;
      background: linear-gradient(135deg, rgba(216, 138, 50, 0.38), rgba(95, 214, 255, 0.32));
      filter: blur(34px);
      opacity: 0.9;
    }

    .cover {
      display: block;
      width: 100%;
      border-radius: 0.7rem;
      box-shadow: 0 2rem 5rem var(--shadow), 0 0 0 1px rgba(243, 234, 217, 0.16);
    }

    .signal {
      position: absolute;
      right: -1.3rem;
      bottom: 8%;
      width: min(42vw, 13rem);
      padding: 1rem;
      border: 1px solid rgba(95, 214, 255, 0.35);
      border-radius: 0.55rem;
      background: rgba(3, 13, 19, 0.68);
      color: #dff8ff;
      box-shadow: 0 0 36px rgba(95, 214, 255, 0.16);
      backdrop-filter: blur(12px);
      animation: float 5.5s ease-in-out infinite;
    }

    .signal strong {
      display: block;
      margin-bottom: 0.4rem;
      font-size: 0.76rem;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--cyan);
    }

    .signal span {
      display: block;
      color: #c8e9f4;
      font-size: 0.88rem;
      line-height: 1.45;
    }

    main {
      position: relative;
      z-index: 1;
    }

    section {
      padding: clamp(4.5rem, 9vw, 8rem) clamp(1rem, 5vw, 5rem);
    }

    .band {
      border-block: 1px solid rgba(243, 234, 217, 0.11);
      background:
        linear-gradient(90deg, rgba(5, 7, 10, 0.52), rgba(8, 18, 28, 0.75)),
        radial-gradient(circle at 10% 20%, rgba(216, 138, 50, 0.1), transparent 24rem);
    }

    .section-grid {
      display: grid;
      grid-template-columns: minmax(0, 0.92fr) minmax(18rem, 1.08fr);
      gap: clamp(2rem, 5vw, 5rem);
      align-items: start;
      max-width: 75rem;
      margin-inline: auto;
    }

    .kicker {
      margin: 0 0 0.9rem;
      color: var(--cyan);
      font-size: 0.78rem;
      letter-spacing: 0.18em;
      text-transform: uppercase;
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
      color: #d8ccba;
      font-family: var(--serif);
      font-size: clamp(1.08rem, 2vw, 1.38rem);
      line-height: 1.65;
    }

    .notice-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 0.8rem;
      margin-top: 1.6rem;
    }

    .notice {
      min-height: 9rem;
      padding: 1rem;
      border: 1px solid rgba(243, 234, 217, 0.14);
      border-radius: 0.55rem;
      background: rgba(255, 255, 255, 0.045);
      box-shadow: inset 0 1px rgba(255, 255, 255, 0.06);
    }

    .notice b {
      display: block;
      color: var(--amber-soft);
      font-size: 0.78rem;
      letter-spacing: 0.12em;
      text-transform: uppercase;
    }

    .notice span {
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
      border: 1px solid rgba(243, 234, 217, 0.14);
      border-radius: 0.55rem;
      overflow: hidden;
      background:
        linear-gradient(135deg, rgba(255, 255, 255, 0.08), transparent),
        rgba(255, 255, 255, 0.035);
    }

    .pdf-object::before {
      position: absolute;
      inset: 1.2rem;
      content: "";
      border: 1px solid rgba(95, 214, 255, 0.18);
      background:
        linear-gradient(180deg, rgba(243, 234, 217, 0.14), transparent 28%),
        repeating-linear-gradient(180deg, rgba(243, 234, 217, 0.24) 0 1px, transparent 1px 1.05rem);
      mask-image: linear-gradient(to bottom, black, transparent 82%);
      opacity: 0.62;
    }

    .pdf-object::after {
      position: absolute;
      right: 1.15rem;
      bottom: 1.15rem;
      content: "PDF";
      color: rgba(95, 214, 255, 0.7);
      font-family: var(--serif);
      font-size: 4.8rem;
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
      border: 1px solid rgba(243, 234, 217, 0.15);
      border-radius: 0.6rem;
      background:
        linear-gradient(180deg, rgba(9, 18, 26, 0.9), rgba(8, 10, 12, 0.95)),
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
        linear-gradient(90deg, rgba(216, 138, 50, 0.09), transparent 15% 85%, rgba(95, 214, 255, 0.09)),
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
      color: var(--amber-soft);
      font-size: 1.4rem;
      font-weight: 400;
    }

    .chapter p {
      margin: 0 0 1.25rem;
    }

    .chapter strong {
      color: #f9f3e7;
      text-shadow: 0 0 18px rgba(95, 214, 255, 0.18);
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
      border-top: 1px solid rgba(243, 234, 217, 0.1);
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
      color: var(--ink);
      border-bottom: 1px solid rgba(95, 214, 255, 0.45);
    }

    @keyframes float {
      0%, 100% {
        transform: translateY(0);
      }
      50% {
        transform: translateY(-0.85rem);
      }
    }

    @keyframes scan {
      from {
        transform: translateX(-6vw);
      }
      to {
        transform: translateX(6vw);
      }
    }

    @media (max-width: 900px) {
      .site-header {
        position: sticky;
      }

      .hero,
      .section-grid,
      .download-panel {
        grid-template-columns: 1fr;
      }

      .hero {
        padding-top: 4rem;
      }

      .cover-stage {
        order: -1;
      }

      .cover-shell {
        max-width: min(82vw, 24rem);
        transform: none;
      }

      .notice-grid {
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

      .signal {
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
  <div class="aurora" aria-hidden="true"></div>

  <header class="site-header">
    <a class="mark" href="#top" aria-label="When We Were Needed home"><span aria-hidden="true"></span>When We Were Needed</a>
    <nav class="nav" aria-label="Primary">
      <a href="#read">Read Week 1</a>
      <a href="#download">Free PDF</a>
      <a href="https://github.com/joshSzep/when-we-were-needed">Repository</a>
      <a href="https://joshszep.com">Books</a>
    </nav>
  </header>

  <main id="top">
    <section class="hero">
      <div class="hero-copy fade-in">
        <p class="eyebrow">A launch site for the novel</p>
        <h1>When We Were Needed</h1>
        <p class="dek">A family crisis becomes a civic fault line in a near-future Los Angeles where care, authority, and machine intimacy have learned to speak in the same soothing voice.</p>
        <div class="actions">
          <a class="button primary" href="#read">Read Week 1</a>
          <a class="button cyan" href="$PDF_FILE">Download the full novel</a>
          <a class="button" href="https://github.com/joshSzep/when-we-were-needed">View the repository</a>
        </div>
      </div>

      <div class="cover-stage fade-in">
        <div class="cover-shell">
          <img class="cover" src="$COVER_FILE" alt="Cover art for When We Were Needed">
          <div class="signal" aria-label="Story signal">
            <strong>2:13 AM</strong>
            <span>Immediate support event initiated. Guardian notification required.</span>
          </div>
        </div>
      </div>
    </section>

    <section class="band">
      <div class="section-grid">
        <div class="fade-in">
          <p class="kicker">The alert</p>
          <h2>What happens when safety arrives before consent?</h2>
        </div>
        <div class="fade-in">
          <p class="section-lede">The opening chapter follows Lena Ortiz-Marks through the night a system tells her that her child is physically safe. It is a promise, a warning, and the first crack in everything her family thought it understood.</p>
          <div class="notice-grid" aria-label="Story themes">
            <div class="notice"><b>Care</b><span>The people trying to help are not always the people with power.</span></div>
            <div class="notice"><b>Trust</b><span>Every interface has a theory of who should be believed first.</span></div>
            <div class="notice"><b>Authority</b><span>A household emergency becomes a question the whole city will inherit.</span></div>
          </div>
        </div>
      </div>
    </section>

    <section id="download">
      <div class="download-panel">
        <div class="fade-in">
          <p class="kicker">Free full novel</p>
          <h2>Download the complete manuscript.</h2>
          <div class="actions">
            <a class="button primary" href="$PDF_FILE">Open the PDF</a>
            <a class="button" href="https://joshszep.com">Joshua Szepietowski's books</a>
          </div>
        </div>
        <a class="pdf-object fade-in" href="$PDF_FILE" aria-label="Open When We Were Needed PDF"></a>
      </div>
    </section>

    <section id="read" class="band">
      <div class="reader-wrap">
        <div class="reader-head fade-in">
          <div>
            <p class="kicker">Read online</p>
            <h2>Week 1</h2>
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
  </main>

  <footer class="footer">
    <div class="footer-inner">
      <span>When We Were Needed by Joshua Szepietowski</span>
      <span><a href="https://github.com/joshSzep/when-we-were-needed">Repository</a> · <a href="https://joshszep.com">More books</a></span>
    </div>
  </footer>

  <script>
    const root = document.documentElement;
    const progress = document.getElementById('progress');
    const reader = document.getElementById('reader');
    const revealItems = document.querySelectorAll('.fade-in');

    const updateProgress = () => {
      const scrollable = document.documentElement.scrollHeight - window.innerHeight;
      const progressValue = scrollable > 0 ? window.scrollY / scrollable : 0;
      progress.style.transform = \`scaleX(\${Math.min(1, Math.max(0, progressValue))})\`;
    };

    window.addEventListener('scroll', updateProgress, { passive: true });
    updateProgress();

    window.addEventListener('pointermove', (event) => {
      root.style.setProperty('--mx', \`\${event.clientX}px\`);
      root.style.setProperty('--my', \`\${event.clientY}px\`);
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
echo "Copied $COVER_FILE and $PDF_FILE into $WEBSITE_DIR"
