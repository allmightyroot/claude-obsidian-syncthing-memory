---
tags: [memory, meta, procedure]
updated: 2026-10-15
---

# /retrospective procedure

Canonical steps for the `/retrospective` skill, in **Claude Code or Claude Desktop**. Sibling of [[reflect-procedure]]: `/reflect` edits durable memory every session; `/retrospective` writes one narrative record of a single notable session, only when the user or Claude thinks it's worth it (migrations, long debugging hunts, multi-session efforts).

## Where output goes
`retrospectives/YYYY-MM-DD-<slug>.md` at the **vault root**, not under `memory/`. It is not indexed and not auto-loaded. Use the user's local date and a 2-4 word kebab-case slug. Create the folder if missing. Never overwrite an existing file; add `-2` to the slug.

## Steps
1. **Review the process, not the product.** Approach, tool use, planning, blockers, course corrections, communication. Be honest and specific.
2. **Write the file** with this frontmatter and template. Skip any section that doesn't apply.
   ```
   ---
   tags: [retrospective]
   date: YYYY-MM-DD
   app: claude-code | claude-desktop| claude-desktop
   session: <Claude Code session name, omit on Desktop>
   project: <repo or topic>
   ---
   # <Title>
   ## Session Goal
   ## What Went Well
   ## What Went Wrong
   ## Lessons Learned
   ## Action Items   (- [ ] checkboxes)
   ## Tips & Tricks
   ## Generalization Opportunities   (skill, hook, command, or agent ideas; only if real)
   ```
3. **Keep it concise.** Process over outcomes. Same scope rule as [[conventions]]: no credentials, secret values or business-confidential data. Write nothing here you would not want a future reader of the vault to see; narrative about people or blame goes nowhere.
4. **Commit (optional).** If the vault is a git repo, commit the file; otherwise your sync tool carries it.
5. **Report** the file path in one line, then offer `/reflect` so durable findings get promoted into `memory/`. Do not run it unasked.

## Don'ts
- Don't write one every session.
- Don't duplicate [[reflect-procedure]]'s memory edits here.
