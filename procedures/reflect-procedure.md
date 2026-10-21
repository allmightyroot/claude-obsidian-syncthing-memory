---
tags: [memory, meta, procedure]
updated: 2026-10-15
---

# /reflect procedure

Canonical steps for the `/reflect` skill, run at the end of a session in **Claude Code or Claude Desktop**. The skill is a thin stub that points here, so improving the procedure means editing this note. Scope rules come from [[conventions]]; don't restate them here.

## Principle
Capture what the *next* session can't re-derive: corrections the user gave, non-obvious gotchas, decisions with their *why*, parked ideas, shifted preferences. A session with nothing like that should end with "nothing worth saving". That is a valid, common result.

## Steps
1. **Review the process, then re-read the session.** What went well, what went wrong or needed a course correction, what would you do differently? Look for: the user correcting or redirecting you; approaches he confirmed worked; surprises (a default, a tool quirk, a bug cause); decisions and the reason; work deferred.
2. **Look for generalization.** A repeated manual pattern, a fix that deserves a hook or guard, or a task that should be a skill goes in as a finding.
3. **Filter.** Drop anything derivable from code, git history, or CLAUDE.md; anything only relevant to this conversation; anything already in the vault (grep `memory/` first).
4. **Apply the scope test from [[conventions]].** Runbooks, patterns and gotchas with real specifics are fine. Credentials, tokens, secret values and business-confidential data are never written. Anything confidential that still needs recording belongs in a local, unsynced file outside the vault.
5. **Classify each survivor:** vault note under `memory/`; that repo's own Claude Code memory (single-repo quirks; Desktop has none, so route to the closest vault note); or a stale/wrong existing note to edit or delete.
6. **Propose, don't write.** Show a table: `# | Finding | Destination | Action (add / update / delete)`, one line each. Wait for the user to approve, trim, or redirect. Never write unapproved.
7. **Write approved items.** Update an existing note rather than adding a near-duplicate. Decision/feedback notes carry **Why** and **How to apply**. Frontmatter on every note. Use the user's local date for `updated:`.
8. **Housekeeping.** Add or fix the `memory/index.md` line for any new or changed note, specific enough that a zero-context session can judge relevance. Add `[[wikilinks]]`.
9. **Log trackable events.** If the session used a Skill, MCP server, or SendFeedback, make sure [[usage-log]] has the row. Add a [[weekly-log]] line if the session did notable work.
10. **Commit (optional).** If the vault is a git repo, commit the edits with a short message. If not, your sync tool carries them.
11. **Report** in two or three lines: what was saved where, and what was deliberately skipped.

## Don'ts
- Don't save secrets or live credentials, or business-confidential data.
- Don't turn the vault into a session log. Findings, not narrative.
- Don't run unprompted; this is the user's end-of-session trigger.
