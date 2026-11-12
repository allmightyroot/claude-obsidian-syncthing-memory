---
name: nitpick
description: Log a specific irritation or friction point in how the user and Claude work together into nitpicks.md, to be fixed later with /nitpick-review. Use when the user runs /nitpick <text>, or when Claude notices something about the user's own way of working that keeps costing time or accuracy. Needs no Obsidian or sync tool.
---

# /nitpick

Append one entry to `nitpicks.md`. This skill only logs; fixing happens in `/nitpick-review`. Don't fix the nitpick now unless the user asks.

## Where the file lives
1. `$CLAUDEBRAIN_VAULT/memory/nitpicks.md` if that variable is set (the full vault setup).
2. Otherwise `$NITPICKS_DIR/nitpicks.md` if set.
3. Otherwise `~/nitpicks/nitpicks.md`.

If the file is missing, create it from this repo's `templates/nitpicks.md` if you can find it, else from the template below, set `updated:` to today's date, and tell the user where it landed.

## Adding an entry
1. Take the nitpick from the command arguments. With no arguments, use what the user just complained about in the conversation, and if that is unclear ask one short question.
2. Pick `for`: `claude` when Claude's behaviour should change (default), `user` when it's about how the user prompts, structures or approves work.
3. Write it as one factual line: what happened and what would have been better. No blame, no drama, and quote the user only when their exact wording matters.
4. **General pattern first, evidence second.** Title and lead the entry with the general pattern, so the fix isn't tied to one case. Then add the concrete evidence the session has as examples: exact command, exact error text, what it should have been. If the conversation has no concrete failure to cite, say so rather than inventing one. Don't speculate about other machines or sessions you can't see.
5. Append it at the end of the list, then bump `updated:` in the frontmatter to the user's local date (it can differ from the environment date).
6. Reply with the entry as written, one line. Don't ask for approval first: the user invoking `/nitpick` is the approval for this one write.

## Claude noting user-side friction
If, during any session, something the user does repeatedly slows the work or causes mistakes (vague scope, a missing constraint, contradictory instructions, approving things in bulk and then objecting), log it with `for: user` using this skill, and tell them in the same turn in one sentence. Keep it constructive: say what would help, not what was wrong with them. Don't log one-off slips. The user wants these so they can decide whether to change their habit, so be honest rather than polite.

## Entry format
```
- [ ] 2026-01-31 · for: claude · Short title: what happened and what would have been better.
  - Seen: project or session, optional
  - Fixed: (filled in by /nitpick-review: where and what fixed it, or "won't fix" and why)
```
A good entry leads with the general pattern and cites specifics as evidence: `- [ ] 2026-01-31 · for: claude · Bashisms in a zsh shell: commands written with bash habits fail on zsh's differences; assume zsh first.` with `  - Seen: examples: an unquoted glob fails with "no matches found"`.

Keep one line per bullet (no hard wrapping) and no blank lines between entries.

## Template if the file is missing
```
---
tags: [memory, nitpicks]
updated: YYYY-MM-DD
---

# Nitpicks

Specific things to fix about how the user and Claude work together. `for: claude` means Claude's behaviour should change, `for: user` means a habit of the user's that would make the work smoother. Add with `/nitpick`, work through with `/nitpick-review`. A ticked box means fixed (or consciously won't-fix), and the `Fixed:` line says where.

## Entries

```
