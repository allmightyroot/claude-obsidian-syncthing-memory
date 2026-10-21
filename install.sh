#!/usr/bin/env bash
# Install the optional skills from this repo.
#
#   ./install.sh --vault PATH [--dry-run]
#
# What it does:
#   - copies skills/<name>/ into ~/.claude/skills/ (replacing an older copy)
#   - seeds <vault>/memory/*-procedure.md from procedures/, ONLY when missing:
#     once a procedure note exists in the vault, the vault copy is canonical
#   - copies tools/vault-lint.py into <vault>/tools/ (always overwritten)
#
# What it deliberately does NOT do: edit ~/.claude/settings.json or the vault's
# memory/index.md. It prints the exact lines for you to add instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
VAULT="${CLAUDEBRAIN_VAULT:-}"
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --vault) VAULT="${2:?--vault needs a path}"; shift ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$VAULT" ] || [ ! -d "$VAULT/memory" ]; then
  echo "error: need an existing vault with a memory/ folder: --vault PATH (or set CLAUDEBRAIN_VAULT)" >&2
  exit 1
fi

run() {
  if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi
}

for skill in "$SCRIPT_DIR"/skills/*/; do
  name="$(basename "$skill")"
  run mkdir -p "$CLAUDE_DIR/skills/$name"
  run cp -r "$skill". "$CLAUDE_DIR/skills/$name/"
  echo "skill $name -> $CLAUDE_DIR/skills/$name"
done

for proc in "$SCRIPT_DIR"/procedures/*.md; do
  base="$(basename "$proc")"
  if [ -f "$VAULT/memory/$base" ]; then
    echo "kept existing $base"
  else
    run cp "$proc" "$VAULT/memory/$base"
    echo "seeded $base -> $VAULT/memory/ (add it to memory/index.md)"
  fi
done

run mkdir -p "$VAULT/tools"
run cp -f "$SCRIPT_DIR/tools/vault-lint.py" "$VAULT/tools/vault-lint.py"
run chmod +x "$VAULT/tools/vault-lint.py"
echo "vault-lint.py -> $VAULT/tools/"

cat <<MSG

Next, by hand:
  1. Tell Claude Code where the vault is. Add to the "env" object in ~/.claude/settings.json:
       "CLAUDEBRAIN_VAULT": "$VAULT"
  2. Add one line per seeded procedure note to $VAULT/memory/index.md.
  3. Claude Desktop does not read ~/.claude/skills. See skills/README.md.
MSG
