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
INDEX_SEEDED=0

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

TODAY="$(date +%F)"
SEEDED=0
INDEX_LINES=""

# Copy src to dest only when dest is missing, setting the first `updated:` line
# to today. Sets SEEDED=1 if it wrote the file; says what it did either way.
seed() {
  local src="$1" dest="$2"
  SEEDED=0
  if [ -f "$dest" ]; then
    echo "kept existing $(basename "$dest")"
    return
  fi
  run mkdir -p "$(dirname "$dest")"
  if [ "$DRY" = 1 ]; then
    echo "[dry-run] seed $dest"
  else
    awk -v t="$TODAY" '!d && /^updated: /{print "updated: " t; d=1; next} {print}' "$src" > "$dest"
  fi
  SEEDED=1
  echo "seeded $(basename "$dest") -> $(dirname "$dest")/"
}

# Queue an index.md line for a note this run seeded (call right after seed).
# The backticks in the descriptions are literal markdown, not command substitution.
# shellcheck disable=SC2016
queue_index_line() {
  local name="$1" desc
  [ "$SEEDED" = 1 ] || return 0
  case "$name" in
    reflect-procedure) desc='`/reflect` steps: re-read the session, apply the scope test, propose a table and wait for approval, then write, index and log' ;;
    retrospective-procedure) desc='`/retrospective` steps: one narrative write-up per notable session into `reflections/`' ;;
    housekeeping-procedure) desc='`/brain-cleanup` steps: lint audit, judgment checks, propose a table, apply after approval' ;;
    brain-conflict-procedure) desc='`/brain-conflict` steps: merge sync-conflict copies without losing content' ;;
    weekly-log) desc='running log of work by week; raw material for resume-fodder' ;;
    resume-fodder) desc='durable accomplishments worth resume language, distilled from the weekly log' ;;
    usage-log) desc='Skills and MCP tools actually used, and feedback filed' ;;
    *) return 0 ;;
  esac
  INDEX_LINES="${INDEX_LINES}- [[${name}]] — ${desc}
"
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
    INDEX_SEEDED="$SEEDED"
    seed "$SCRIPT_DIR/templates/weekly-log.md" "$VAULT/memory/weekly-log.md"
    queue_index_line weekly-log
    seed "$SCRIPT_DIR/templates/usage-log.md" "$VAULT/memory/usage-log.md"
    queue_index_line usage-log
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
    queue_index_line "${proc%.md}"
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
    [ -n "$VAULT" ] && queue_index_line weekly-log
    seed "$SCRIPT_DIR/templates/resume-fodder.md" "$dir/resume-fodder.md"
    [ -n "$VAULT" ] && queue_index_line resume-fodder
  fi
done

if [ "$NEEDS_VAULT" = 1 ]; then
  run mkdir -p "$VAULT/tools"
  run cp -f "$SCRIPT_DIR/tools/vault-lint.py" "$VAULT/tools/vault-lint.py"
  run chmod +x "$VAULT/tools/vault-lint.py"
  echo "vault-lint.py -> $VAULT/tools/"

  if [ -n "$INDEX_LINES" ]; then
    if [ "$INDEX_SEEDED" = 1 ]; then
      if [ "$DRY" = 1 ]; then
        echo "[dry-run] would add index lines to $VAULT/memory/index.md"
      else
        printf '%s' "$INDEX_LINES" >> "$VAULT/memory/index.md"
        echo "added index lines for the seeded notes to the new index.md"
      fi
      INDEX_STEP=""
    else
      INDEX_STEP="  - Add these lines to $VAULT/memory/index.md:
$INDEX_LINES"
    fi
  else
    INDEX_STEP=""
  fi

  cat <<MSG

Next, by hand:
  - Tell Claude Code where the vault is. Add to the "env" object in ~/.claude/settings.json:
       "CLAUDEBRAIN_VAULT": "$VAULT"
${INDEX_STEP}  - To have Claude load the index at the start of every session, see examples/hooks/.
  - Claude Desktop does not read ~/.claude/skills. See skills/README.md.
MSG
else
  echo
  echo "Done. In Claude Code, run /worklog."
fi
