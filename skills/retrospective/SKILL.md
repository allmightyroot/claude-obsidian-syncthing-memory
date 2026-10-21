---
name: retrospective
description: Write a one-off narrative retrospective of the current session (what went well, what went wrong, lessons, action items) into the vault's reflections/ folder. Use when the user runs /retrospective or asks for a session retrospective after a notable piece of work. Works in Claude Code and Claude Desktop.
---

# Retrospective

The procedure is canonical in the vault, so it can improve without re-installing this skill.

1. Read `memory/retrospective-procedure.md` from the vault and follow it exactly.
   - Claude Code: the vault root is `$CLAUDEBRAIN_VAULT`. If that is unset, ask the user for the path and stop. Use that same root for every vault path in the procedure.
   - Claude Desktop: read the same note through the Obsidian MCP Connector.
2. If the vault is unreachable, say so and stop. Do not write the file elsewhere.

Output goes to `reflections/` at the vault root. Afterward, offer `/reflect` but don't run it unasked.
