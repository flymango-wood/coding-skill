#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/.claude"
CLAUDE_ROOT="${CLAUDE_HOME:-$HOME/.claude}"

usage() {
  cat <<EOF
Install APL (Automated Production Line) for Claude Code.

Usage:
  $(basename "$0") [--help] [--skip-deps]

Options:
  --skip-deps    Skip dependency installation (npm, mmdc, openspec)

What this installs:
  - openspec CLI (npm global)
  - mmdc / Mermaid CLI (npm global)
  - All APL skills into ~/.claude/skills/
EOF
}

log()    { echo "🔧 $1"; }
ok()     { echo "✅ $1"; }
info()   { echo "ℹ️  $1"; }
backup() { echo "💾 $1"; }
err()    { echo "❌ $1" >&2; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || { err "Required command not found: $1. Please install it first."; exit 1; }
}

install_npm_pkg() {
  local pkg="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd already installed: $(command -v "$cmd")"
  else
    log "Installing $pkg..."
    npm install -g "$pkg"
    ok "Installed $cmd"
  fi
}

install_deps() {
  require_command node
  require_command npm

  install_npm_pkg "@fission-ai/openspec@latest" openspec
  install_npm_pkg "@mermaid-js/mermaid-cli" mmdc
}

sync_skill() {
  local src="$1"
  local name
  name="$(basename "$src")"
  local dst="$CLAUDE_ROOT/skills/$name"

  if [[ -e "$dst" ]]; then
    local bak_dir="${TMPDIR:-/tmp}/apl-install-bak"
    mkdir -p "$bak_dir"
    rm -rf "$bak_dir/$name"
    cp -R "$dst" "$bak_dir/$name"
  fi

  rm -rf "$dst"
  cp -R "$src" "$dst"
  ok "Installed skill: $name"
}

install_skills() {
  log "Installing APL skills into $CLAUDE_ROOT/skills/"
  mkdir -p "$CLAUDE_ROOT/skills"

  while IFS= read -r skill_dir; do
    sync_skill "$skill_dir"
  done < <(find "$ASSETS_DIR/skills" -mindepth 1 -maxdepth 1 -type d | sort)
}

main() {
  local skip_deps=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)     usage; exit 0 ;;
      --skip-deps)   skip_deps=true; shift ;;
      *)             err "Unknown argument: $1"; usage >&2; exit 1 ;;
    esac
  done

  echo "🚀 APL Installer"
  echo ""

  if [[ "$skip_deps" == false ]]; then
    install_deps
    echo ""
  fi

  install_skills

  echo ""
  echo "🎉 APL install complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Open Claude Code in your project"
  echo "  2. Run: apl init"
}

main "$@"
