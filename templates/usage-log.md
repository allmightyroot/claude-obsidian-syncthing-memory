---
tags: [memory, usage-log]
updated: YYYY-MM-DD
---

<!--
Template: copy into your vault as memory/usage-log.md (or whatever you want to call
it) and link it from memory/index.md.

Every other template here holds durable facts - things true regardless of which
session reads them. This one is different: it's a deliberate exception to "one file
per topic, not a log" (see vault-conventions.md), because what it tracks only exists
as a log. A session can see a Skill fire, an MCP tool actually get called, or a bug
get reported RIGHT NOW - but it has no way to reconstruct that after the fact if it
wasn't written down at the time. Skip this template entirely if that's not useful to
you; nothing else here depends on it.

Concretely useful for: a real answer (not a guess) when someone asks how you're
actually using AI day to day: which Skills or MCP connections you've actually
exercised, not just what's theoretically available; and a durable record of bugs/
feedback you've flagged, since a tool's own local feedback queue may only keep a
handful of drafts and won't survive being cleared.

The logging habit itself is a *policy*, not data, so it belongs in whatever behavioral
rules file you keep (see vault-conventions.md or your own preferences note) - something
like: "whenever a Skill fires, an MCP tool actually gets called, or a feedback draft
gets created, add a row here in the same turn, not when asked." Keeping the instruction
there and the rows here mirrors the same split this whole vault uses everywhere else:
policy in one place, data in another.
-->

# Usage Log

Running catalog of concrete things I've actually used Claude for - not hypothetical capability claims, real examples with dates and enough context to mean something later. Newest entries at top. Keep each entry to what happened + why it's worth citing, not a full task writeup - the real detail already lives in that project's own memory if it's needed.

## Entries

<!--
- **YYYY-MM-DD — One-line description** (`project-or-repo`): what happened, and the
  one sentence that makes it worth having on this list rather than just in that
  project's own history.
-->

## Skills used

Claude Code ships named "Skills" - packaged instructions for a specific kind of task - that fire when the task calls for one. Only log one here once it's actually fired, not because it exists.

| Date | Skill | Used for | Project |
|---|---|---|---|

## MCP servers

MCP (Model Context Protocol) servers connect Claude to a live external system - a Kubernetes API, a project tracker, a chat platform - instead of it just knowing about one in the abstract. Two tables on purpose: what's configured/available right now, separate from a real log of when one actually got used for something. Don't list a server as "used" just because it's connected.

### Available (as of YYYY-MM-DD)

| Server | What it's for |
|---|---|

### Used

| Date | Server | Used for | Project |
|---|---|---|---|

## Bugs / feedback reported

Whatever your tool's feedback/bug-report mechanism is, its local history may not be durable - a fixed-size queue, cleared on update, tied to one machine. This is the backstop.

| Date | Title | Type | Status | Notes |
|---|---|---|---|---|
