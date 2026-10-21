---
tags: [memory, meta, procedure]
updated: 2026-10-19
---

# /brain-cleanup procedure

The canonical steps for the `/brain-cleanup` skill (also triggered by "should we clean up your brain?"). The skill (`skills/brain-cleanup/SKILL.md` in this repo) is a thin stub that points here, so improving the procedure means editing this note. Prompted by the user only: not on a schedule and not at the end of every session. Run it from Claude Code, since several checks need a shell and other working directories.

## Steps
1. **Mechanical audit.** From the vault root run `python3 -I tools/vault-lint.py --health` and `python3 -I tools/vault-lint.py`. `--health` reports broken wikilinks, notes in `memory/` or `handoff/` not reachable from `memory/index.md` (linked from it, or from a note it links), an over-budget index, notes over ~12KB, `updated:` more than 180 days old, and `*.sync-conflict-*` files. It is report-only. Pointer stubs (body under ~300 bytes containing a `[[link]]`) are exempt from the unindexed and stale checks: they exist only so old links resolve, and need not be reachable from the index.
2. **Judgment checks** (these need reading, not a script):
   - Project memory in any recently-touched working directory that duplicates something already in, or belonging in, this vault. Consolidate it here and leave a one-line pointer stub behind so existing wikilinks still resolve.
   - Notes that have grown into several unrelated subtopics (split candidates; start from the `large-note` hits), and `memory/index.md` lines that no longer describe their note accurately.
   - Scope violations: anything that crept in that you decided not to keep here (client, employer, or personal detail). Re-check against the scope test in [[conventions]] (runbook or pattern with real specifics = fine; credential or business-confidential data = never). Include `handoff/`, which is client-facing.
   - Large chronological logs (a migration diary, an incident timeline). Default: a short outcome note (current state, decisions, gotchas) that links to an archive note holding the full log. Condense only where the cuts are pure duplication. Never just delete history. An archive note created this way gets `lint-skip: [large-note]` in its frontmatter.
   - Uncommitted changes, or a messy history if commit messages no longer make it useful.
3. **Sync conflicts.** For each `*.sync-conflict-*` hit, merge content into the canonical file and delete the copy.
4. **Propose, don't write.** Show a table: `# | Finding | Action (merge / split / fix link / reword index / delete / none) | Target`. Wait for the user to approve, trim, or redirect. Never write or delete unapproved.
5. **Apply approved items.** Anything the user accepts as-is gets the matching `lint-skip: [rule]` frontmatter key (`large-note`, `stale`, `stale-project-note`, `unindexed`) instead of being re-proposed next time; `--health` then skips that rule for that note. Keep `memory/index.md` under 6000 bytes (the SessionStart hook output is capped at ~10K chars). Check each index line still matches its note.
6. **Re-check.** Run `python3 -I tools/vault-lint.py --fix <files you wrote>` and `python3 -I tools/vault-lint.py --health` again; fix what remains or report it.
7. **Commit (Claude Code only, optional)** if the vault is a git repo, per the git habit in [[conventions]], then report in a few lines what changed and what was left alone.

## Don'ts
- Don't run unprompted.
- Don't save secrets or live credentials; this vault never holds them.
