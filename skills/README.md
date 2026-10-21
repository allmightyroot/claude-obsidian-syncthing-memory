# skills

Optional skills that turn the vault conventions into slash commands. Each one is a
thin stub: the real procedure is a note in your vault (`memory/<name>-procedure.md`,
seeded from [`procedures/`](../procedures)), so you can improve it by editing the
note instead of reinstalling the skill.

| Skill | What it does | Needs a vault? |
|---|---|---|
| `/reflect` | End-of-session capture of corrections, gotchas and decisions, proposed as a table first | yes |
| `/retrospective` | One narrative write-up of a notable session into `reflections/` | yes |
| `/brain-cleanup` | Housekeeping audit: broken links, orphans, oversized or stale notes | yes |
| `/brain-conflict` | Merge Syncthing `*.sync-conflict-*` copies without losing content | yes |
| `/worklog` | Weekly work log plus a short resume-worthy list, as plain markdown | no (defaults to `~/worklog/`) |

## Install (Claude Code)

```
./install.sh --vault /path/to/your/vault --dry-run   # see what it would do
./install.sh --vault /path/to/your/vault
```

The installer copies the skills into `~/.claude/skills/`, seeds any missing procedure
notes into the vault, and copies `tools/vault-lint.py` into `<vault>/tools/`. It never
edits `settings.json` or your index; it prints the lines to add. A skill that already
exists in `~/.claude/skills/` is kept, since it may be your own customized version; pass
`--force` to replace it.

The skills find the vault through the `CLAUDEBRAIN_VAULT` environment variable.

`/worklog` works without any of this: copy `skills/worklog/` into `~/.claude/skills/`
and run it. It falls back to `~/worklog/`, or `$WORKLOG_DIR` if you set it.

## Claude Desktop

Desktop does not read `~/.claude/skills`. Zip each skill folder and upload it under
Settings > Capabilities > Skills:

```
cd skills && zip -r reflect.zip reflect
```

The stub reads its procedure through the Obsidian MCP Connector, so later edits to the
procedure note apply without re-uploading. Re-upload only if `SKILL.md` itself changes.
