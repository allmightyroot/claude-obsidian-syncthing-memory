<!--
Template: copy into your vault as memory/conventions.md (or whatever you want to
call it) and link it from memory/index.md.

This file is the "backend" for the whole system. Prompts like "should we clean up
your brain?" have no built-in meaning to Claude - they work only because this note
exists in the vault, is linked from the index, and spells out what those requests
should actually do. Without it, a session with no memory of how you set this up has
nothing to go on. Edit freely; these are starting conventions, not rules handed down.
-->

---
tags: [memory, meta, convention]
updated: YYYY-MM-DD
---

# Vault Conventions

How this vault works, and how it relates to per-project Claude Code memory.

## The boundary

- **This vault is the single source of truth for cross-cutting facts** — durable
  preferences, standards, working-style rules, infrastructure that spans projects,
  and anything that's really a fact about me rather than about one codebase.
- **Per-project memory should not duplicate that.** Each project's memory opens with
  a short pointer block to this vault, then carries only genuinely project-specific
  content: that repo's incident history, its gotchas, config quirks with no reuse
  value elsewhere.
- A technical pattern that spans more than one repo counts as cross-cutting and
  belongs here — per-project memory can't see across repos, and re-deriving the same
  pattern in each one is exactly the drift this vault exists to prevent.
- When a new cross-cutting fact comes up while working in a project, it goes straight
  into this vault, not that project's local file — even though it was learned there.

## File structure

- One file per topic, not one append-only log. Update the relevant file when
  something changes rather than adding another dated entry forever.
- Frontmatter (`tags`, `updated`) on every note so it stays filterable as it grows.
- Link related notes with `[[wikilinks]]`. A link to a note that doesn't exist yet is
  fine — it marks something worth writing later.
- Every topic file gets a one-line description in `index.md`.

## Index lines are load-bearing

Only `index.md` is auto-loaded into sessions; topic files are read on demand. So each
index line is doing real work — a vague or stale line means a fact effectively can't
be recalled even though it's written down. Treat those lines with the same care as a
commit message: specific enough that a session with zero other context can tell
whether the full note is worth opening.

## What makes a good entry

These conventions came out of working together and correcting each other — expect to
keep adjusting them. The ones that have earned their place so far:

- **Lead with the fact or rule, then say why, then say when it applies.** The *why*
  is the part that matters most: a rule without its reason gets followed off a cliff
  at the first edge case, while a rule with its reason can be reasoned about. "Don't
  mock the database in these tests" is a rule; "because mocked tests passed while a
  prod migration broke" is what lets a future session know when the rule bends.
- **Record what worked, not just what went wrong.** Corrections are easy to notice and
  easy to write down. Confirmations are quieter and just as important — an approach
  that was explicitly approved, an unusual call that turned out right. A memory made
  only of corrections drifts steadily more cautious, because it remembers every
  mistake and none of the validated judgment.
- **Use absolute dates.** "Thursday" and "last month" are meaningless six months on;
  write `2026-03-05`.
- **Write for a reader with zero context.** No pronouns without antecedents, no
  references to "the thing we discussed" — the whole point is being read by a session
  that wasn't there.
- **Prefer updating an existing note to adding a new one.** Two half-notes on the same
  topic is how this gets useless.

## What not to save

- Anything derivable from the current state of a codebase — architecture, file paths,
  conventions, project structure. Reading the code is authoritative; a stale note is
  worse than no note.
- Git history or who-changed-what. `git log` and `git blame` already know.
- Fix recipes for bugs already fixed. The fix is in the code; the reasoning is in the
  commit message.
- Ephemeral state: in-progress task details, what's currently on screen, conversation
  context that dies with the session.
- **Credentials of any kind** — tokens, keys, passwords, full webhook URLs. This vault
  replicates to every synced device, lands in every backup, and gets read into Claude
  context routinely. Record *where* a secret lives, never its value. If one lands here
  by accident, rotate it rather than just deleting the line: it's already in sync
  history and backups.

## Optional: logging what only exists in the moment

Most of this vault holds durable facts - true no matter which session reads them.
A few things aren't like that: a Skill firing, an MCP tool actually getting called,
a bug you flagged to the tool vendor. A session can see those happen right now and
has no way to reconstruct them later if they weren't written down at the time -
not "hard to find," genuinely gone. If that's useful to have a real record of (e.g.
"how am I actually using this day to day," not a guess), see `templates/usage-log.md`.

That template is data, not instructions - the trigger belongs here instead, as its
own rule: *whenever a Skill fires, an MCP tool actually gets called, or you create a
feedback/bug draft, add a row to the usage log in the same turn, don't wait to be
asked.* Same split as everything else in this vault: policy in one place, data in
another, so you're not hunting through a log for the rule that explains why it
exists.

## Housekeeping

Triggered by asking — e.g. "should we clean up your brain?" — not on a schedule, and
not proactively at the end of every session. When asked, check:

- Project memory in any recently-touched working directory that duplicates something
  already in, or belonging in, this vault. Consolidate it here and leave a one-line
  pointer stub behind so existing `[[wikilinks]]` still resolve.
- Notes that have grown into several unrelated subtopics (candidates for splitting),
  and `index.md` lines that no longer describe their file accurately.
- Uncommitted changes, if this vault is under git — and whether the commit messages
  still make the history useful.
- Stray `*.sync-conflict-*` files anywhere under the synced folder, a sign two writers
  edited the same file at once. Resolve by merging content into the canonical file and
  deleting the conflict copy.

Run it from Claude Code — checking project memory across working directories needs
filesystem access the vault alone doesn't provide.

## Git habit

If this vault is under git: after editing anything here during a session, commit before
finishing. That captures both this session's edits and whatever another Claude surface
wrote since the last commit — writes from elsewhere arrive as plain file changes via
sync, so git only notices them at the next commit rather than tracking them live.
