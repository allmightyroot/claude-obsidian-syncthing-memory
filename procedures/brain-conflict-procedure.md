---
tags: [memory, meta, procedure]
updated: YYYY-MM-DD
---

# /brain-conflict procedure

Canonical steps for the `/brain-conflict` skill. Syncthing writes a `*.sync-conflict-*` copy when two devices edit the same file before they sync. Nothing is lost, but the vault now holds two versions of one note until someone merges them. Prompted by the user, or when a session notices a conflict file.

## Steps
1. **Find them.** From the vault root: `find . -name '*.sync-conflict-*' -not -path './.git/*'`. In Claude Desktop, list vault files and filter for `sync-conflict`.
2. **Diff each against its canonical file.** The canonical file is the same name without the `.sync-conflict-<date>-<time>-<device>` part.
3. **Merge without losing content.** Keep every distinct fact from both versions. For `memory/index.md`, keep the union of the index lines and re-check each still matches its note. Where the two versions contradict each other, don't pick silently: show both and ask.
4. **Propose, don't write.** Show a table: `# | Conflict file | Canonical file | Proposed merge`. Wait for the user to approve, trim, or redirect. Never write or delete unapproved.
5. **Apply approved merges.** Write the merged result to the canonical file, then delete the conflict copy. Run `python3 -I tools/vault-lint.py --fix <files you wrote>`.
6. **Report** in a line or two what was merged and what was left alone.

## Don'ts
- Don't delete a conflict copy before its content is merged.
- Don't run unprompted.
