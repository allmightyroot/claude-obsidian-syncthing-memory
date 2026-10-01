<!--
Template: an example of a working-style rule, i.e. a note that tells Claude HOW to
respond rather than recording a fact. Copy it into your vault as its own note (e.g.
memory/status-table.md), or paste the section into whatever behavioral-rules note you
already keep, and link it from memory/index.md. Optional; nothing else here depends
on it.

It's included because it travels well. On any multi-step effort (a migration, a
multi-PR change, anything that runs across several sessions), a running table is
much easier to scan than a paragraph, and it keeps a record of what's already
done instead of just what's left. Because it lives in the vault, Claude Desktop and
every Claude Code session use the same format, so a table that one session produces
reads the same when another session picks it up.

Change it to suit you: different markers, columns, or thresholds. Replace "the user"
with your own name if you like; a note in your own vault can speak about you directly.
-->

---
tags: [memory, feedback, working-style]
updated: YYYY-MM-DD
---

# Status / next-steps updates: one running table

When the user asks "what's next" / "where are we" on an effort with several steps (roughly
4+, or spanning multiple turns, sessions, or people), answer with a single markdown table,
not prose or a bullet checklist:

| # | Step | Status | Owner |
|---|------|--------|-------|
| 1 | Create service account | ✅ Done | Claude |
| 2 | Grant repo read scope | ⛔ Blocked: needs org-admin | Platform team |
| 2a | Verify token in CI | 🔲 Not started | Claude |
| 3 | Migrate cron jobs | 🔄 In progress: 3 of 5 moved | Claude |
| 4 | ~~Mirror to second region~~ | ❌ Dropped: covered by step 3 | — |

**Why:** The table is a running *history* of the effort that the user can scan in seconds,
not a TODO list that empties out as items finish.

**How to apply:**
- **Status markers, a fixed set of five:** ✅ done · 🔄 in progress · ⛔ blocked · 🔲 not
  started · ❌ dropped. Put the marker first, then a few words. For blocked or dropped rows,
  the reason goes in the same cell ("⛔ Blocked: needs org-admin"), not in a separate notes
  column. Avoid gray glyphs like ➖ because they nearly disappear in dark mode.
- **Rows never leave the table.** Finished rows stay ✅ and abandoned ones become ❌ with a
  reason, so decisions don't silently disappear. Exception for long efforts (~15+ rows):
  collapse a run of early ✅ rows into one row ("1–9 | Initial setup | ✅ Done |") so the
  table still fits on a screen.
- **Numbers are stable IDs.** Never renumber. A new step goes at the end, or uses a letter
  suffix (2a) if it belongs between existing steps, so "step 4" means the same thing every
  time.
- **Owner is always a name:** Claude, the user's name, a team, or a specific other session.
  Use names, not "you"/"me", because tables get relayed between sessions and lose the context
  that says who "you" is. A done row keeps the name of whoever did it. Use "—" only for
  dropped rows.
- **Short cells.** Keep Step to about 8 words and Status to a short phrase, since wide tables
  wrap badly in a terminal. Longer context goes in a line or two *below* the table, never in
  the cells.
- **Regenerate the whole table each time** status changes, rather than describing a diff of
  the last one. Re-reading the current state is easier than following a changelog.
