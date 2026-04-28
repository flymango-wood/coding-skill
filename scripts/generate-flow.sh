#!/usr/bin/env bash

set -euo pipefail

MMDC_BIN="${MMDC_BIN:-mmdc}"
OUTPUT_DIR="./openspec/flows"

usage() {
  cat <<EOF
Generate timestamped Mermaid flow diagram outputs.

Usage:
  $(basename "$0") <flow-name> [output_dir]

Reads Mermaid content from stdin, writes .mmd and renders .svg.
EOF
}

detect_chrome() {
  for candidate in \
    "${FORGEVIA_DRAW_CHROME_PATH:-}" \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
  do
    [[ -n "$candidate" && -x "$candidate" ]] && echo "$candidate" && return 0
  done
  for cmd in google-chrome chrome chromium; do
    command -v "$cmd" >/dev/null 2>&1 && command -v "$cmd" && return 0
  done
  return 1
}

main() {
  [[ "${1:-}" == "--help" ]] && usage && exit 0
  [[ $# -lt 1 ]] && usage >&2 && exit 1

  local name="$1"
  local out_dir="${2:-$OUTPUT_DIR}"
  local mmd_path="$out_dir/${name}.mmd"
  local svg_path="$out_dir/${name}.svg"
  local -a cmd

  mkdir -p "$out_dir"
  cat > "$mmd_path"

  cmd=("$MMDC_BIN" -i "$mmd_path" -o "$svg_path")

  if chrome="$(detect_chrome 2>/dev/null)"; then
    local cfg
    cfg="$(mktemp "${TMPDIR:-/tmp}/apl-flow-puppeteer.XXXXXX")"
    trap 'rm -f "$cfg"' EXIT
    printf '{"executablePath":"%s"}\n' "$chrome" > "$cfg"
    cmd+=(-p "$cfg")
  fi

  "${cmd[@]}"

  echo "✅ Flow written: $mmd_path"
  echo "✅ SVG rendered: $svg_path"
}

main "$@"
