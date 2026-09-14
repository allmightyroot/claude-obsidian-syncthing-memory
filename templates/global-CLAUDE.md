<!--
Template: a block to add to your own ~/.claude/CLAUDE.md.

This is the read/write policy for the vault - the SessionStart hook loads the
index automatically, but this is what tells Claude the vault is authoritative and
when to write back to it. Adjust the path and name to match your setup, and merge
it into whatever your ~/.claude/CLAUDE.md already says rather than replacing it.
-->

## Persistent memory: the shared vault is canonical for cross-cutting facts

I keep a shared memory vault (plain markdown, synced across my devices) at
`<path/to/vault>`. Durable notes live under `memory/`; start at `memory/index.md`.

**Cross-cutting facts** — my preferences, standing working-style rules, standards I
hold, infrastructure that spans projects — belong in that vault, not duplicated into
individual projects' memory. When you learn one, write it into the relevant topic
file there (creating a new topic file with frontmatter plus an `index.md` line if
nothing fits), even if you learned it while working in a specific project.

**Project-specific memory** — a repo's own incident history, gotchas, and config
quirks with no reuse value elsewhere — stays in that project's local Claude Code
memory, which is what gets auto-loaded when I'm working there.

The vault isn't read automatically beyond its index; check the relevant topic file
explicitly when something it covers comes up.

**Never write credentials into the vault** — no tokens, keys, passwords, or full
webhook URLs. It replicates to every synced device and into backups, and it's read
into Claude context routinely. Record where a secret lives, never its value.

**When you find a stray memory file elsewhere** that duplicates a cross-cutting fact
already in (or belonging in) the vault, consolidate it into the vault as you come
across it and leave a one-line pointer stub behind so existing `[[wikilinks]]` still
resolve. Opportunistic as you touch things — not a proactive sweep.
