---
name: brain-cleanup
description: Periodic housekeeping of the memory vault - broken links, orphaned or oversized notes, duplicated project memory, stale index lines, scope violations. Use when the user runs /brain-cleanup or asks "should we clean up your brain?" or to tidy/audit the vault.
---

# /brain-cleanup

Prompted by the user, never on a schedule or unprompted at the end of a session. The procedure is canonical in the vault, so it can improve without re-installing this skill.

1. Read `memory/housekeeping-procedure.md` from the vault and follow it exactly.
   - Claude Code: the vault root is `$CLAUDEBRAIN_VAULT`. If that is unset, ask the user for the path and stop. Use that same root for every vault path in the procedure.
   - Claude Desktop: read the same note through the Obsidian MCP Connector. The checks that need a shell (`vault-lint.py --health`, git, other working directories) are Claude Code only; say which you skipped.
2. If the vault is unreachable, say so and stop. Do not improvise a procedure.

Core rule if you only remember one thing: run `python3 -I tools/vault-lint.py --health` first, add the judgment items, propose everything in a table, and wait for approval before writing or deleting anything.
