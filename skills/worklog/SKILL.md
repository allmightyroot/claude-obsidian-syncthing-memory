---
name: worklog
description: Keep a running weekly work log and a short list of resume-worthy accomplishments, as plain markdown. Use when the user runs /worklog, asks to update the weekly log, or says to add something to resume fodder. Needs no Obsidian or sync tool.
---

# Worklog

Two plain markdown files: `weekly-log.md` (what happened, week by week) and `resume-fodder.md` (the few things worth resume language, promoted up from the log).

## Where the files live
1. `$CLAUDEBRAIN_VAULT/memory/` if that variable is set (the full vault setup).
2. Otherwise `$WORKLOG_DIR` if set.
3. Otherwise `~/worklog/`. Create it on first use, seeded from this repo's `templates/weekly-log.md` and `templates/resume-fodder.md` if you can find them, else with the headings below. Tell the user where it landed.

## Updating the log
1. Read the last entry's date. If it is more than two weeks old, say so even if this session did nothing notable.
2. Add or extend the entry for the current week (heading `### Week of YYYY-MM-DD`, the Monday, in the user's local date). One bullet per thread of work: what kind of work and roughly how substantial (kicked off, continuing, wrapped up).
3. Skip routine or no-op sessions. A week with nothing worth noting gets no entry.
4. Generalize before writing: describe the kind of work and its scale, not client names, internal system names, credentials or confidential figures. Show the user the proposed bullets and wait for approval before writing.

## Promoting to resume fodder
Only when something is significant: a new technology demonstrated, a project worth naming, a concrete number worth citing. Distill from the log into `resume-fodder.md`: what was done, scale, outcome, and a one-line "resume angle". Not everything in the log graduates. Propose first, write after approval.

## Daily or weekly cadence
This skill has no scheduler. The user runs it when a chunk of work wraps, or at the end of the week. If they want it every day, that is just running `/worklog` daily; the weekly heading groups the days.
