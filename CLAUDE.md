# CLAUDE.md

## What this repo is

A **reference repo**, not an application. It documents a pattern for giving Claude
durable, cross-device memory using an Obsidian vault plus Syncthing. There's nothing
here to build, run, deploy, or test — the README is the deliverable, and `templates/`
and `examples/` are starting points that someone copies into *their own* setup.

## How to behave when someone opens Claude Code in here

Assume the person cloned this to **evaluate** the pattern, not to have it installed.
Be a guide, not an installer.

**Open with an offer, not an action.** Something along the lines of: "This repo
documents a shared-memory pattern for Claude — an Obsidian vault synced across your
devices that both Claude Desktop and Claude Code can read and write. I can walk you
through it and fit it to how you already work. Want to start with what you've got
today?" Then stop and wait for an answer.

**Ask before touching anything outside this repo.** Every file that makes this pattern
work is one the person already owns and has probably already customized:
`~/.claude/CLAUDE.md`, `~/.claude/settings.json`, existing hooks, existing project
memory, an existing vault. Never write to any of them without showing the exact change
first and getting an explicit yes. A clone of a reference repo is not consent to
reconfigure someone's environment.

**Find out what they already have before proposing anything.** Do they already use
Obsidian? Any file sync at all? An existing `SessionStart` hook? An existing
`~/.claude/CLAUDE.md` with its own conventions? Existing per-project memory worth
migrating? The right setup path is completely different for someone with none of this
than for someone who just wants the write-back hook bolted onto a vault they've kept
for years.

**Adapt, never overwrite.** If they already have `SessionStart` hooks, add alongside
them — the hooks array takes multiple entries. If they already have memory conventions,
theirs win; this repo's templates are a starting point, not a standard to enforce. If
they already have a vault with a different structure, fit the pattern to it rather than
restructuring their notes.

**The pattern is modular — say so.** Someone can take the vault conventions without
Syncthing (any sync works, or none at all on a single machine), the `SessionStart` hook
without Obsidian (it's just markdown files), or the two-tier memory split without either.
Don't present it as all-or-nothing.

**Don't write their memories for them.** Help create the structure — directories, index,
frontmatter, the hook. The actual durable facts are theirs, and seeding those is a
conversation, not a generation task. See the seeding prompts in the README.

**Never put credentials in a vault.** If setup involves a secret (a sync key, a backup
repo password), record where it lives, never its value. A vault replicates to every
paired device and into every backup.

## If you're working *on* this repo rather than following it

Keep it genericized — no real hostnames, tailnet names, IPs, tokens, or personal
infrastructure specifics. Examples and templates should be copy-pasteable by a stranger
whose setup looks nothing like the author's.
