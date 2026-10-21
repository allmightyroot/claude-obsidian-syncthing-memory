#!/usr/bin/env bash
# Install the optional skills from this repo.
#
#   ./install.sh [--skills a,b,c] [--vault PATH [--init]] [--dry-run] [--force]
#
# Skills: reflect, retrospective, brain-cleanup, brain-conflict, worklog
# (default: all of them).
#
# What it does:
#   - copies skills/<name>/ into ~/.claude/skills/, but SKIPS any skill that already
#     exists there (it may be your own customized version); --force replaces it
#   - worklog needs no vault: it seeds ~/worklog/ (or $WORKLOG_DIR), or
#     <vault>/memory/ when --vault is given
#   - every other skill needs a vault: --vault PATH, a folder with a memory/ inside.
#     --init creates that folder and seeds starter notes (conventions, index,
#     weekly log, usage log) so a plain folder works as a vault. Any sync tool is optional.
#   - seeds <vault>/memory/*-procedure.md for the chosen skills, ONLY when missing:
#     once a procedure note exists in the vault, the vault copy is canonical
#   - copies tools/vault-lint.py into <vault>/tools/ (always overwritten)
#
# What it deliberately does NOT do: edit ~/.claude/settings.json or the vault's
# memory/index.md. It prints the exact lines for you to add instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
VAULT="${CLAUDEBRAIN_VAULT:-}"
SKILLS="reflect,retrospective,brain-cleanup,brain-conflict,worklog"
DRY=0
FORCE=0
INIT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --vault) VAULT="${2:?--vault needs a path}"; shift ;;
    --skills) SKILLS="${2:?--skills needs a comma-separated list}"; shift ;;
    --init) INIT=1 ;;
    --dry-run) DRY=1 ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

run() {
  if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi
}

# The procedure note a skill reads from the vault; empty for worklog.
procedure_for() {
  case "$1" in
    reflect) echo reflect-procedure.md ;;
    retrospective) echo retrospective-procedure.md ;;
    brain-cleanup) echo housekeeping-procedure.md ;;
    brain-conflict) echo brain-conflict-procedure.md ;;
    worklog) echo "" ;;
    *) echo "error: unknown skill '$1'" >&2; exit 2 ;;
  esac
}

# Copy src to dest only when dest is missing; says what it did.
seed() {
  local src="$1" dest="$2"
  if [ -f "$dest" ]; then
    echo "kept existing $(basename "$dest")"
  else
    run mkdir -p "$(dirname "$dest")"
    run cp "$src" "$dest"
    echo "seeded $(basename "$dest") -> $(dirname "$dest")/"
  fi
}

IFS=',' read -r -a CHOSEN <<< "$SKILLS"
NEEDS_VAULT=0
for name in "${CHOSEN[@]}"; do
  procedure_for "$name" > /dev/null
  [ -d "$SCRIPT_DIR/skills/$name" ] || { echo "error: no such skill: $name" >&2; exit 2; }
  [ "$name" = worklog ] || NEEDS_VAULT=1
done

if [ "$NEEDS_VAULT" = 1 ]; then
  if [ -z "$VAULT" ]; then
    echo "error: these skills need a vault: pass --vault PATH (add --init to create it), or set CLAUDEBRAIN_VAULT" >&2
    echo "       for just the work log, use: ./install.sh --skills worklog" >&2
    exit 1
  fi
  if [ ! -d "$VAULT/memory" ]; then
    if [ "$INIT" = 1 ]; then
      run mkdir -p "$VAULT/memory"
    else
      echo "error: $VAULT/memory does not exist; add --init to create it" >&2
      exit 1
    fi
  fi
  if [ "$INIT" = 1 ]; then
    seed "$SCRIPT_DIR/templates/vault-conventions.md" "$VAULT/memory/conventions.md"
    seed "$SCRIPT_DIR/templates/memory-index.md" "$VAULT/memory/index.md"
    seed "$SCRIPT_DIR/templates/weekly-log.md" "$VAULT/memory/weekly-log.md"
    seed "$SCRIPT_DIR/templates/usage-log.md" "$VAULT/memory/usage-log.md"
  fi
fi

for name in "${CHOSEN[@]}"; do
  skill="$SCRIPT_DIR/skills/$name"
  if [ -d "$CLAUDE_DIR/skills/$name" ] && [ "$FORCE" = 0 ]; then
    echo "kept existing skill $name (use --force to replace it)"
  else
    run mkdir -p "$CLAUDE_DIR/skills/$name"
    run cp -r "$skill/." "$CLAUDE_DIR/skills/$name/"
    echo "skill $name -> $CLAUDE_DIR/skills/$name"
  fi

  proc="$(procedure_for "$name")"
  if [ -n "$proc" ]; then
    seed "$SCRIPT_DIR/procedures/$proc" "$VAULT/memory/$proc"
  fi
done

for name in "${CHOSEN[@]}"; do
  if [ "$name" = worklog ]; then
    if [ -n "$VAULT" ]; then
      dir="$VAULT/memory"
    else
      dir="${WORKLOG_DIR:-$HOME/worklog}"
    fi
    seed "$SCRIPT_DIR/templates/weekly-log.md" "$dir/weekly-log.md"
    seed "$SCRIPT_DIR/templates/resume-fodder.md" "$dir/resume-fodder.md"
  fi
done

if [ "$NEEDS_VAULT" = 1 ]; then
  run mkdir -p "$VAULT/tools"
  run cp -f "$SCRIPT_DIR/tools/vault-lint.py" "$VAULT/tools/vault-lint.py"
  run chmod +x "$VAULT/tools/vault-lint.py"
  echo "vault-lint.py -> $VAULT/tools/"

  cat <<MSG

Next, by hand:
  1. Tell Claude Code where the vault is. Add to the "env" object in ~/.claude/settings.json:
       "CLAUDEBRAIN_VAULT": "$VAULT"
  2. Add one line per seeded procedure note to $VAULT/memory/index.md.
  3. To have Claude load the index at the start of every session, see examples/hooks/.
  4. Claude Desktop does not read ~/.claude/skills. See skills/README.md.
MSG
else
  echo
  echo "Done. In Claude Code, run /worklog."
fi
