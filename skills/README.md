# skills

Optional skills that turn the vault conventions into slash commands. Most are thin
stubs: the real procedure is a note in your vault (`memory/<name>-procedure.md`,
seeded from [`procedures/`](../procedures)), so you can improve it by editing the
note instead of reinstalling the skill. `/worklog`, `/nitpick` and `/nitpick-review`
are self-contained instead and need no vault.

| Skill | What it does | Needs a vault? |
|---|---|---|
| `/reflect` | End-of-session capture of corrections, gotchas and decisions, proposed as a table first | yes |
| `/retrospective` | One narrative write-up of a notable session into `retrospectives/` | yes |
| `/brain-cleanup` | Housekeeping audit: broken links, orphans, oversized or stale notes | yes |
| `/brain-conflict` | Merge Syncthing `*.sync-conflict-*` copies without losing content | yes |
| `/worklog` | Weekly work log plus a short resume-worthy list, as plain markdown | no (defaults to `~/worklog/`) |
| `/nitpick` | Log one specific friction point in how you and Claude work together to `nitpicks.md`, as a checkbox entry (`for: claude` or `for: user`); Claude also logs habits of yours that keep costing time | no (defaults to `~/nitpicks/`) |
| `/nitpick-review` | Work through the open nitpicks together, fix each one (rule, hook, skill, note or habit change), then tick it off with a note of where it was fixed | no (same file) |

## Install (Claude Code)

Pick what you want. Add `--dry-run` to any of these to see what it would do first.

```
./install.sh --skills worklog                       # work log only; no vault needed
./install.sh --skills nitpick,nitpick-review        # friction log and review; no vault needed
./install.sh --skills reflect,retrospective \
             --vault ~/claude-memory --init         # plus session capture, in a plain folder
./install.sh --vault /path/to/your/vault            # everything, into an existing vault
```

- `worklog` needs no vault. It seeds `~/worklog/` (or `$WORKLOG_DIR`), or `<vault>/memory/` if you pass `--vault`.
- `nitpick` and `nitpick-review` need no vault either. They share one `nitpicks.md`, seeded into `~/nitpicks/` (or `$NITPICKS_DIR`), or `<vault>/memory/` if you pass `--vault` or set `CLAUDEBRAIN_VAULT`. With a vault, add the index line yourself.
- The other four need a vault, which is just a folder with a `memory/` inside. `--init` creates it and seeds starter notes (conventions, index, weekly log, usage log), so a plain folder works and Obsidian or a sync tool is optional.
- The installer copies the skills into `~/.claude/skills/`, seeds the procedure notes for the skills you chose (only when missing), and copies `tools/vault-lint.py` into `<vault>/tools/` when a vault is involved.
- It never edits `settings.json`. For a vault it just created with `--init` it adds index lines for the notes it seeded; for an existing vault it prints the lines for you to add to your own `index.md`.
- A skill that already exists in `~/.claude/skills/` is kept, since it may be your own customized version; pass `--force` to replace it.

The skills find the vault through the `CLAUDEBRAIN_VAULT` environment variable.

## Claude Desktop

Desktop does not read `~/.claude/skills`. Zip each skill folder and upload it under
Settings > Capabilities > Skills:

```
cd skills && zip -r reflect.zip reflect
```

The stub reads its procedure through the Obsidian MCP Connector, so later edits to the
procedure note apply without re-uploading. Re-upload only if `SKILL.md` itself changes.

`nitpick` and `nitpick-review` are self-contained, so zip and upload them the same way and re-upload whenever their `SKILL.md` changes. Desktop can only reach `nitpicks.md` through the Obsidian MCP Connector, so on Desktop it needs the vault setup.
