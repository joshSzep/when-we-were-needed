#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_MD="$ROOT_DIR/When We Were Needed.md"
COVER_IMAGE="$ROOT_DIR/when-we-were-needed.png"
OUTPUT_PDF="$ROOT_DIR/When We Were Needed.pdf"
BOOK_TITLE="When We Were Needed"
AUTHOR="Joshua Szepietowski"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

require_tool pandoc
require_tool pdflatex
require_file "$SOURCE_MD"
require_file "$COVER_IMAGE"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

BODY_MD="$TMP_DIR/body.md"
HEADER_TEX="$TMP_DIR/header.tex"
COVER_TEX="$TMP_DIR/cover.tex"
TMP_PDF="$TMP_DIR/When We Were Needed.pdf"

awk '
  /^##[[:space:]]+/ {
    if (seen_phase) {
      print ""
      print "\\newpage"
      print ""
    }
    seen_phase = 1
    after_phase = 1
    body = 1
    print
    next
  }

  !body {
    next
  }

  /^###[[:space:]]+/ {
    if (seen_chapter && !after_phase) {
      print ""
      print "\\newpage"
      print ""
    }
    seen_chapter = 1
    after_phase = 0
    print
    next
  }

  /^[[:space:]]*$/ {
    print
    next
  }

  {
    after_phase = 0
    print
  }
' "$SOURCE_MD" > "$BODY_MD"

cat > "$HEADER_TEX" <<'TEX'
\usepackage[T1]{fontenc}
\usepackage{tgpagella}
\usepackage{microtype}
\usepackage{setspace}
\usepackage{xcolor}
\usepackage{pagecolor}
\usepackage{graphicx}
\usepackage{eso-pic}
\usepackage{fancyhdr}
\usepackage{titlesec}
\usepackage{xparse}

\definecolor{chapterink}{HTML}{202020}
\definecolor{phaseink}{HTML}{5C4634}
\definecolor{rulegray}{HTML}{B8B2AA}
\definecolor{headergray}{HTML}{66615C}

\pagecolor{white}
\linespread{1.08}
\setlength{\parindent}{1.25em}
\setlength{\parskip}{0pt}
\raggedbottom
\clubpenalty=10000
\widowpenalty=10000
\displaywidowpenalty=10000

\pagestyle{fancy}
\fancyhf{}
\setlength{\headheight}{15pt}
\fancyhead[C]{\small\itshape\textcolor{headergray}{\nouppercase{\leftmark}}}
\fancyfoot[C]{\small\textcolor{headergray}{\thepage}}
\renewcommand{\headrulewidth}{0.25pt}
\renewcommand{\footrulewidth}{0pt}
\renewcommand{\headrule}{\hbox to\headwidth{\color{rulegray}\leaders\hrule height \headrulewidth\hfill}}

\titleformat{\subsection}[display]
  {\normalfont\Large\scshape\centering\color{phaseink}}
  {}
  {0pt}
  {}
\titlespacing*{\subsection}{0pt}{0.14\textheight}{2.5em}

\titleformat{\subsubsection}[display]
  {\normalfont\huge\bfseries\centering\color{chapterink}}
  {}
  {0pt}
  {}
\titlespacing*{\subsubsection}{0pt}{2.75em}{2em}

\let\PandocSubsubsection\subsubsection
\RenewDocumentCommand{\subsubsection}{s o m}{%
  \markboth{#3}{#3}%
  \IfBooleanTF{#1}{%
    \IfNoValueTF{#2}{\PandocSubsubsection*{#3}}{\PandocSubsubsection*[#2]{#3}}%
  }{%
    \IfNoValueTF{#2}{\PandocSubsubsection{#3}}{\PandocSubsubsection[#2]{#3}}%
  }%
}
TEX

cat > "$COVER_TEX" <<TEX
\\thispagestyle{empty}
\\AddToShipoutPicture*{%
  \\AtPageLowerLeft{%
    \\includegraphics[width=\\paperwidth,height=\\paperheight]{\\detokenize{$COVER_IMAGE}}%
  }%
}
\\null
\\clearpage
\\setcounter{page}{1}
\\pagestyle{fancy}
TEX

pandoc "$BODY_MD" \
  --from markdown+raw_tex \
  --standalone \
  --pdf-engine=pdflatex \
  --include-in-header "$HEADER_TEX" \
  --include-before-body "$COVER_TEX" \
  --metadata title-meta="$BOOK_TITLE" \
  --metadata author-meta="$AUTHOR" \
  --metadata lang=en-US \
  --variable documentclass=article \
  --variable classoption=oneside \
  --variable fontsize=11pt \
  --variable geometry:paperwidth=6in \
  --variable geometry:paperheight=9in \
  --variable geometry:left=0.72in \
  --variable geometry:right=0.72in \
  --variable geometry:top=0.78in \
  --variable geometry:bottom=0.72in \
  --variable geometry:headsep=0.18in \
  --variable geometry:footskip=0.34in \
  --variable linkcolor=black \
  --variable urlcolor=black \
  --variable toccolor=black \
  --output "$TMP_PDF"

mv "$TMP_PDF" "$OUTPUT_PDF"
echo "Generated $OUTPUT_PDF"
