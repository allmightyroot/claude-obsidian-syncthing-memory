---
name: brain-conflict
description: Find and resolve Syncthing conflict copies (*.sync-conflict-*) in the memory vault, merging indexes and notes without losing content. Use when the user runs /brain-conflict or reports a sync conflict in the vault.
---

# /brain-conflict

The canonical procedure lives in the vault: read `memory/brain-conflict-procedure.md` and follow it. Propose a table of findings and wait for approval before writing or deleting anything.

- **Claude Code**: the vault root is `$CLAUDEBRAIN_VAULT`. If that is unset, ask the user for the path and stop.
- **Claude Desktop**: read the note with the Obsidian MCP connector (path `memory/brain-conflict-procedure.md`) and find conflicts by listing vault files and filtering for `sync-conflict`; don't assume a filesystem path.
