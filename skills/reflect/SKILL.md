---
name: reflect
description: End-of-session reflection that captures durable findings (corrections, gotchas, decisions, preferences) into the memory vault. Use when the user runs /reflect or says to wrap up the session and update memory. Works in Claude Code and Claude Desktop.
---

# Reflect

Run at the end of a session. The procedure is canonical in the vault, so it can improve without re-installing this skill.

1. Read `memory/reflect-procedure.md` from the vault and follow it exactly.
   - Claude Code: the vault root is `$CLAUDEBRAIN_VAULT`. If that is unset, ask the user for the path and stop. Use that same root for every vault path in the procedure.
   - Claude Desktop: read the same note through the Obsidian MCP Connector.
2. If the vault is unreachable, say so and stop. Do not improvise a procedure or write memory elsewhere.

Core rule if you only remember one thing: propose findings in a table and wait for approval before writing anything. "Nothing worth saving" is a valid result.
