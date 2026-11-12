---
name: nitpick-review
description: Work through the open entries in nitpicks.md with the user and actually fix them (rule, hook, skill, note, or a change of habit), then tick them off with a note of where it was fixed. Use when the user runs /nitpick-review or asks to go through the nitpicks. Needs no Obsidian or sync tool.
---

# /nitpick-review

Work together to resolve entries in `nitpicks.md` (location as in the `/nitpick` skill: `$CLAUDEBRAIN_VAULT/memory/`, else `$NITPICKS_DIR`, else `~/nitpicks/`). If the file doesn't exist, say so and stop.

## Procedure
1. Read the file. Show the open (`- [ ]`) entries as one table: `# | Date | For | Nitpick | Status`, with numbers stable for this review. Ignore any `- [ ]` inside code fences, since those are format examples. Offer a suggested order (quick wins and ones hitting the most sessions first). Ask which to take, or whether to go in order. Closed entries are not shown unless asked.
2. For each chosen entry, discuss before changing anything. Say what you think the root cause is and where the fix belongs, and push back if the nitpick would steer the user off something better or if the fix is out of proportion to the annoyance. Candidate homes:
   - a standing rule in the user's global `CLAUDE.md`, plus the matching note if their vault keeps the canonical copy of that rule
   - a note in the vault or project memory
   - a hook, skill, or `settings.json` change when the behaviour should be enforced rather than remembered (a rule Claude must remember is weaker than one the harness runs)
   - for `for: user` entries: a concrete suggestion of what the user could do differently (a prompt habit, a template, a checklist), and the user decides whether to adopt it
   - won't fix, with a reason
3. Propose the specific change and wait for approval. Edit, commit and push are separate approvals.
4. Make the change, then check it works where that's possible (run the hook, read back the installed copy, re-read the rule in context). If it can't be verified, say so.
5. Only then close the entry: change `- [ ]` to `- [x]` and fill in the `Fixed:` line with where and what, for example `Fixed: 2026-01-31, rule added to ~/.claude/CLAUDE.md`, or `Won't fix: reason`. Bump `updated:` in the frontmatter. Leave the entry in place; never delete closed ones.
6. If a fix turns out not to hold, un-tick the entry and add a dated note under it rather than writing a new entry.
7. End with the regenerated table showing what changed, and say what is still open.

## Rules
- Don't batch-approve: one nitpick, one proposal, one decision.
- Keep the one-line-per-bullet, no-loose-list formatting when editing the file.
