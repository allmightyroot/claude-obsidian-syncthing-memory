# Changelog

Notable changes to this repo, newest first. Loosely follows
[Keep a Changelog](https://keepachangelog.com/) — grouped by date rather than
version, since this is a reference/template repo, not a versioned package.

## 2026-10-01

### Added
- `examples/hooks/session-name.sh` and `examples/statusline/statusline.sh`:
  optional per-session names, shown in the status line, so that several
  concurrent Claude Code sessions can be told apart and can refer to each
  other ("ask Glados"). Names persist per session ID across compaction and
  resume, avoid collisions with other active sessions, and can be changed
  on request. This came from real use: running one session per repo during a
  migration, then naming them by hand because "the other session" was too
  vague. New README section: "Optional: name your sessions".
- `templates/status-table.md`: an optional working-style rule, and the first
  template here that tells Claude *how to respond* rather than recording a
  fact. Status and next-steps answers become one running
  `# | Step | Status | Owner` table with a fixed set of five markers
  (chosen to stay visible in dark mode), step numbers that never change,
  named owners so tables still make sense when relayed between sessions, and
  finished or dropped rows kept as history. It was worked out across two real
  vaults before being written up generically here.

## 2026-09-16

### Added
- `templates/usage-log.md` — an optional log for things a session can only see
  in the moment (Skills firing, MCP tools actually getting called, feedback/bug
  drafts) and can't reconstruct later if they weren't written down. Grew out of
  hitting exactly that problem: a bug report from a couple weeks prior was gone
  with no way to recover it.
- `vault-conventions.md`: new "Optional: logging what only exists in the moment"
  section — the logging *policy* (when to add a row) lives here; the template is
  just the data, same policy/data split used everywhere else in this vault.

## 2026-09-14

Initial build of the repo.

### Added
- Architecture writeup: an Obsidian vault synced via Syncthing as the single
  source of truth for cross-cutting Claude memory, read/written by Claude
  Desktop (via the Obsidian MCP Connector) and Claude Code (as plain files)
  alike.
- `examples/hooks/`: a working `SessionStart` hook that probes candidate vault
  paths and loads the vault index into context, with write-back instructions
  so the vault doesn't decay into a stale snapshot.
- `templates/`: `vault-conventions.md` (the note that lives *in* the vault and
  gives "should we clean up your brain?" actual meaning), `memory-index.md`,
  `global-CLAUDE.md`, `project-memory-pointer.md`.
- `CLAUDE.md`: this repo is a reference, not an installer — cloning it should
  prompt a walkthrough fitted to the reader's existing workflow, never silent
  edits to their `~/.claude` config, hooks, or an existing vault.
- README sections on what makes a good entry, what must never go in a vault
  (credentials, the employer-owned-machine question), and a verification step.
- Claude Desktop extension install gotchas (the actual failure mode: dragging
  the `.mcpb` onto the chat window silently mis-attaches it as a file instead
  of installing), seeding prompts for a vault's first memories, and a
  Housekeeping section.

### Changed
- Clarified Syncthing is peer-to-peer, not client-server — an always-on hub is
  a convenience for devices that are rarely online together, not a
  requirement.
- Housekeeping section now explains the trigger phrase does nothing on its
  own — it only works because the checklist itself lives in a vault note
  Claude can discover.
- Migration prompt now tells Claude to add frontmatter and an `index.md` line
  for any new topic file it creates, matching the from-scratch prompt.

### Removed
- `examples/k8s/` — documented one specific always-on-hub hosting choice that
  was really optional, adding more surface area than value.

### Fixed
- Jagged box edges in the architecture diagram (inconsistent column widths).
