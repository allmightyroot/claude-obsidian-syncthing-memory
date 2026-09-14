# Claude + Obsidian + Syncthing: Shared Memory Architecture

How we give Claude (both the desktop app and Claude Code) a single, durable,
cross-device memory by treating an Obsidian vault as the source of truth and
using Syncthing — not a paid sync service — to keep it consistent everywhere.

## The problem this solves

Claude Code's built-in per-project memory is scoped to one working directory.
That's great for project-specific facts (this repo's incidents, this
codebase's gotchas) but terrible for anything that spans multiple projects or
is really just a fact about *you* — standing preferences, infrastructure
topology, working-style rules. Left alone, every project re-derives the same
cross-cutting facts independently, and they drift out of sync with each
other.

Claude Desktop, separately, has no persistent memory at all beyond a single
conversation unless you give it one.

The fix: one plain-Markdown vault that both surfaces can read and write,
kept in sync across every machine that needs it, with a lightweight
convention for what belongs in the shared vault vs. what stays local to a
project.

## Architecture

```
┌────────────────────────────┐              ┌─────────────────────────────────┐
│ Laptop / workstation       │              │ Always-on host (cluster/server) │
│                            │              │                                 │
│ Claude Desktop             │◄── Syncthing │ Syncthing (k8s or native)       │
│  └─ Obsidian MCP Connector │    protocol  │  - GUI  (HTTPS)                 │
│      (local, talks MCP)    │   (mesh sync,│  - Sync (TCP/UDP 22000)         │
│                            │  TCP/UDP     │  - restic sidecar → backup      │
│ Obsidian.app               │   22000) ──► │                                 │
│  └─ vault (local folder,   │              │ Claude Code                     │
│     kept in sync)          │              │  reads/writes the vault         │
│                            │              │  directly, as plain files       │
└────────────────────────────┘              └─────────────────────────────────┘
```

*(This shows the topology we happen to run — an always-on peer in
Kubernetes plus a laptop. Syncthing is peer-to-peer with no client/server
distinction, so the right-hand box isn't required; see [Setup](#1-deploy-syncthing-an-always-on-hub-is-optional).)*

Three pieces, each doing one job:

1. **Obsidian vault** — a folder of plain Markdown files. This is the actual
   memory; Obsidian itself is just one of several front ends onto it.
2. **Syncthing** — a peer-to-peer, self-hosted file-sync mesh (not Obsidian
   Sync, which is a paid subscription service). This is genuinely
   client-server-free: every device in the mesh is an equal peer, and any
   two peers that are online at the same time sync directly with each
   other. Nothing here requires a dedicated always-on server — two laptops
   that are occasionally both open will sync fine, they just won't get new
   changes until they're both online together. We run one peer in
   Kubernetes as an always-on hub (below) purely so every other device has
   *something* reachable to sync against at any hour, without needing to
   coordinate everyone's laptops being open simultaneously — that's a
   convenience, not a protocol requirement.
3. **Two Claude integrations onto the same files**:
   - **Claude Desktop** talks to the vault through the [Obsidian MCP
     Connector](https://obsidian.md) community plugin, exposed as an MCP
     server on `localhost`, installed as a Claude Desktop extension.
   - **Claude Code**, running on a machine that already has the vault synced
     onto local disk, just reads and writes the Markdown files directly —
     no MCP server, no plugin, it's a regular filesystem path.

Because both integrations converge on the same plain files, and Syncthing
keeps those files identical across every machine, "memory" is just "files in
a folder" — no database, no proprietary format, nothing that can only be
read by one tool.

**Scope, so nobody's surprised:** this reaches Claude Desktop and Claude
Code. It does *not* reach claude.ai in a browser or the Claude mobile app —
both run server-side with no access to your filesystem or a local MCP
server, and nothing in this pattern changes that.

## Memory conventions

Not every fact belongs in the shared vault. We split memory into two tiers:

- **Cross-cutting facts** (about you, your standards, shared infrastructure
  topology, working-style preferences) → live in the vault, one Markdown
  file per topic, all linked from a single `memory/index.md`.
- **Project-specific memory** (a particular repo's incident history, a
  service's config quirks, anything with zero reuse value outside that one
  codebase) → stays in that project's own local Claude Code memory, *not*
  the vault.

Each project's local memory starts with a short pointer block instead of
duplicating vault content (full version in
[`templates/project-memory-pointer.md`](templates/project-memory-pointer.md)):

```markdown
## Shared memory
Cross-cutting facts about me, my standards, and my infrastructure live in the
shared vault, not here — see memory/index.md at /path/to/vault. Read that
first, and write new cross-cutting facts there rather than into this file.
Only memory specific to *this* repo belongs below.
```

Only `memory/index.md` gets auto-loaded into every Claude Code session (via
a `SessionStart` hook — see [Setup](#4-auto-load-the-vault-index-into-claude-code)).
Everything else in the vault is read on demand, which means each topic's
one-line description in `index.md` is doing real work: a vague or stale line
effectively makes that fact unrecallable even though it's written down.
Treat those lines with the same care as a commit message.

When the same fact shows up duplicated in more than one project's local
memory, or in a project when it really belongs in the vault, consolidate it
into the vault and leave a one-line pointer stub behind so old
`[[wikilinks]]` elsewhere still resolve.

## Setup

### 1. Deploy Syncthing (an always-on hub is optional)

**If you don't already run anything server-shaped**, skip this step
entirely: install native Syncthing on each device you want the vault on
(laptop, desktop, phone) and pair them directly with each other. That's a
fully working, purely peer-to-peer mesh with no server of any kind —
devices sync whenever two of them happen to be online together. Plenty of
setups stop right there.

The only reason to add a dedicated always-on peer is convenience: without
one, two devices that are never open at the same time (e.g. a work laptop
and a home desktop) won't sync until they happen to overlap. An always-on
peer just guarantees something is always reachable, so every other device
converges quickly regardless of when it's turned on — it is still just
another peer in the mesh, not a server the others depend on.

If you do want that, run it somewhere that's always reachable — a
Kubernetes cluster, a home server, a small always-on VM, whatever you've
already got. The official `syncthing/syncthing` container image works
fine for this; wire it up with the same shape you'd give any small
stateful service (persistent storage for its config + synced folder, the
GUI on 8384, the sync protocol on 22000). We run ours as a single-replica
Deployment on a small k3s cluster, fronted by a private overlay-network
ingress for the GUI — nothing about that is required, it's just what we
already had.

Key details worth knowing regardless of how you host it:

- **Single replica only.** Syncthing's config/database isn't safe for
  concurrent multi-writer access, so this is explicitly a
  `strategy: Recreate` Deployment (or the rollout deadlocks trying to attach
  a `ReadWriteOnce` volume to two pods at once).
- **The sync protocol needs its own network path.** If your ingress
  controller is HTTP(S)-only (common with mesh/VPN-based ingress), the GUI
  (port 8384, HTTP) can go through it, but the raw sync protocol (TCP *and*
  UDP 22000) needs a separate `LoadBalancer`-type Service on your private
  network — an HTTP ingress can't carry it.
- **Syncthing 2.x CLI changed** from 1.x: `--no-default-folder` was removed
  from both `generate` and `serve` (a default folder now always gets
  created on first run — delete it manually in the GUI), and `generate`/
  `serve` now require `--config` and `--data` together, or `--home` to set
  both to the same path.

Add native Syncthing installs on any other machine (laptop, other servers)
and pair them into the same device mesh, sharing the same folder ID.

One caveat if you're picturing this on a phone: Android is well served, but
Syncthing has no official iOS client — the available options are
third-party and constrained by iOS background-execution limits, so a phone
may sync only while the app is open. Worth checking the current state
before you plan around mobile access.

### 2. Create the vault

Point one Syncthing folder at an empty directory and open it as an Obsidian
vault (or just treat it as a plain Markdown folder if you don't use
Obsidian's UI on every device). Inside it, create:

```
memory/
  index.md          # one-line-per-topic index; the only file auto-loaded every session
  <topic>.md         # one file per cross-cutting topic, linked from index.md
```

Each topic file gets frontmatter so it stays filterable as it grows:

```markdown
---
tags: [memory, <topic>]
updated: YYYY-MM-DD
---
```

### 3. Connect Claude Desktop via the Obsidian MCP Connector

Two separate installs here, and the second one is the part that actually
trips people up.

1. **In Obsidian**: Settings → Community plugins → Browse, search for the
   MCP Connector plugin, install and enable it. It runs a local MCP server
   (check the plugin's own settings tab for the port it's using). This part
   is genuinely straightforward.
2. **In Claude Desktop**: the plugin gives you a `.mcpb` (or `.dxt`)
   extension file to install — this is the fiddly part.
   - Don't drag the file onto Claude Desktop's main chat window. There's a
     dialog that looks like it wants exactly that ("Drag .MCPB or .DXT file
     here to install"), but dropping it on the chat window just attaches it
     as a chat file — it never installs.
   - Instead go to **Settings → Extensions → Advanced settings** and install
     the file from there. Don't go looking under **Developer** settings —
     that's for building/loading your own MCP server from source, not for
     installing a packaged extension, and the two are easy to confuse.
   - Restart Claude Desktop afterward and confirm the extension shows as
     connected before relying on it in a conversation.

(Menu wording may drift between Claude Desktop versions — if these exact
labels don't match what you see, look specifically for **Extensions**, not
**Developer**.)

### 4. Auto-load the vault index into Claude Code

On any machine where Claude Code runs against the synced vault path,
configure a `SessionStart` hook that reads `memory/index.md` and injects it
as context at the start of every session. A working hook is in
[`examples/hooks/`](examples/hooks/) — copy it to `~/.claude/hooks/`, make it
executable, and register it in `~/.claude/settings.json` using the snippet
next to it. It needs `jq`.

Claude Code needs no plugin — it reads and writes the vault's Markdown files
as a normal filesystem path, same as any other file in a project.

Two things in that hook are worth understanding rather than just copying:

**It probes a list of candidate paths.** The vault lands somewhere different
on each machine (a Linux box's system path vs. a Mac's Syncthing folder), and
the same hook runs everywhere, so it tries several locations and exits 0
silently if none exist. A missing vault isn't an error — it just means this
machine isn't part of the mesh.

**It injects instructions, not just content.** This is the part that's easy
to miss and the reason the system doesn't go stale. Loading the index only
gives Claude a *read* path; without an explicit instruction, new facts keep
getting written into whatever project you happened to be sitting in, and the
vault slowly decays into a stale snapshot. So the hook's injected text also
says, in effect: when you learn something cross-cutting, write it into the
vault rather than this project's local memory — and keep project-specific
things local. Pair it with the same policy in your own `~/.claude/CLAUDE.md`
(template in [`templates/global-CLAUDE.md`](templates/global-CLAUDE.md)) so
it holds even in sessions where the hook didn't run.

### 5. Write down the conventions *inside* the vault

The single most-skipped step. Everything above gets facts into the vault;
this is what keeps them coherent six months later.

Claude has no built-in idea of what your vault is for, what belongs in it, or
what "clean it up" means. Those rules have to exist as a note *in the vault
itself*, linked from `index.md`, so any future session can find and follow
them. Copy [`templates/vault-conventions.md`](templates/vault-conventions.md)
in as a starting point and edit it to taste — it covers the vault/project
boundary, what makes a good entry, what never belongs (credentials), the
housekeeping checklist, and the git habit.

Starter [`index.md`](templates/memory-index.md) and
[per-project pointer block](templates/project-memory-pointer.md) templates are
there too.

### 6. Seed the vault with your first memories

Two starting points, depending on whether you're migrating existing
context or starting clean. In both cases, do this from **Claude Code**
if it involves reading files outside the vault itself — Claude Desktop
only sees the vault, through the MCP connector, not your other project
directories.

**Migrating scattered per-project memory into the vault** (e.g. you
already have Claude Code memory in several repos and want to pull the
cross-cutting parts into one place):

```
Inventory every existing project memory file across the working
directories I use. For each fact you find, classify it:
- Cross-cutting (about me, a durable preference, a standard, or shared
  infrastructure) -> write it into the vault under memory/ (a new topic
  file if nothing existing fits, with frontmatter - tags, updated - and
  a one-line description added to index.md), then remove it from the
  project file.
- Project-specific (only meaningful in the context of that one repo) ->
  leave it where it is.
Replace whatever's left in each project's memory with a short pointer
block at the top referencing the vault, followed by only the
project-specific content that survived.
```

**Starting from nothing** (either surface can run this one, since it's
just drafting):

```
Help me draft memory/index.md for a new shared memory vault. Ask me what
categories of durable facts are worth tracking for me (standing
preferences, infrastructure, working-style rules, ongoing projects —
whatever's relevant), then create one short topic file per category with
frontmatter (tags, updated) and a one-line description of each, linked
from index.md.
```

If you're bootstrapping a *second* vault that should follow an existing
one's conventions, start the drafting conversation in a session that
already has the existing vault's `index.md` loaded as context, then hand
the actual file/directory creation off to a session with real filesystem
access (Claude Code, or another agentic session) — a plain chat can
describe the structure but can't create the directories or wire up
Syncthing itself.

### 7. Exclude version-control internals from the sync, if you version the vault

If you `git init` the vault for real history/rollback, exclude `.git/` from
Syncthing's sync (via `.stignore`) rather than letting Syncthing sync it —
git's internal files (index, refs, `HEAD`) aren't safe under
concurrent-writer sync the way plain Markdown is, especially when more than
one machine in the mesh might run git against the same working copy.

**That takes two lines, not one** — the directory entry and its contents are
matched separately, and the obvious single-line version silently syncs
everything inside `.git/` anyway:

```
myvault/.git
myvault/.git/**
```

(Paths are relative to the root of the *synced folder*, not the vault, so
include the vault's directory name if it sits inside a larger shared folder.)

`.gitignore` inside the vault should separately exclude Obsidian's own
workspace-state directory (`.obsidian/` — pure churn) and any plugin
installer artifacts.

Habit: after editing anything under the vault in a session, commit before
finishing up. This captures your own edits plus whatever the other
integration wrote since the last commit — writes from the other side land
as plain file changes via Syncthing, so git only sees them at the next
commit, not live.

### 8. Back it up

Point a backup job at the vault's on-disk location, independent of Syncthing
itself — Syncthing replicates state, it doesn't protect you from deleting or
corrupting a file, because the deletion replicates too. Any backup tool works;
ours is a `restic` job that snapshots the vault on a timer with 7 daily /
4 weekly / 6 monthly retention and posts a pass/fail notification to a chat
webhook on each run, so a silently broken backup doesn't go unnoticed for
months.

### 9. Confirm it actually works

Both halves of this fail *silently*, so check rather than assume.

**Claude Desktop**: start a new conversation and ask it something only the
vault would know — "what's in my memory vault?" or a question answered by a
topic file. If it has no idea, the extension is installed but not connected;
recheck Settings → Extensions.

**Claude Code**: start a session in some unrelated directory — the whole point
is that this works everywhere, not just where the vault lives — and ask what it
knows about you from the vault index. If nothing came through, run the hook by
hand (`~/.claude/hooks/load-vault-index.sh`) and check that it prints JSON.
Silence means it found no vault at any of its candidate paths and exited 0, so
fix the path list; a `jq: command not found` means install `jq`.

**The sync itself**: edit a file on one device and confirm it lands on another.
Then check the Syncthing GUI for the folder showing "Up to Date" on both,
rather than trusting that no news is good news.

## What makes a good entry

The mechanics above get facts *into* the vault. What keeps it useful is what
you write in them, and these conventions are worth stealing:

- **Lead with the fact, then say why, then say when it applies.** The *why* is
  the part that earns its keep. A rule without its reason gets followed off a
  cliff at the first edge case; a rule with its reason can be reasoned about.
  "Don't mock the database in these tests" is a rule — "because mocked tests
  passed while the prod migration broke" is what tells a future session when
  the rule bends and when it doesn't.
- **Record what worked, not only what went wrong.** Corrections are easy to
  notice and easy to write down. Confirmations are quieter — an approach that
  got explicitly approved, an unusual call that turned out right. A memory
  built only from corrections drifts steadily more timid, because it remembers
  every mistake and none of the validated judgment.
- **Use absolute dates.** "Thursday" is meaningless six months later.
- **Write for a reader with zero context**, because that's literally the
  audience: a session that wasn't there. No dangling pronouns, no "the thing we
  discussed".
- **Don't store what's derivable.** Architecture, file paths, conventions, who
  changed what — the codebase and `git log` are authoritative and always
  current. A stale note about code is worse than no note, because it gets
  believed.

Expect this list to keep evolving. Working out what's worth remembering is a
back-and-forth: Claude proposes, you correct, and the corrections themselves
are some of the most valuable things to write down.

## What not to put in it

Worth deciding deliberately up front, because a vault is quietly one of the
most sensitive files you own — it accumulates a detailed picture of you, in
plaintext, replicated to every synced device and into every backup, and read
into model context routinely.

- **No credentials, ever.** No tokens, keys, passwords, or full webhook URLs.
  It's a tempting place to stash them and a genuinely bad one: a secret written
  here lands on every paired device and in every snapshot at once, and survives
  in git history and sync history after you delete the line. Record *where* a
  secret lives, never its value — and if one lands there by accident, rotate it
  rather than just deleting it.
- **Think before syncing a personal vault onto a machine you don't own.** On an
  employer-managed laptop, anything on disk is plausibly theirs to inspect, and
  a personal memory vault is a lot more than notes about work.
- **Prefer separate vaults over one mixed vault** when contexts genuinely
  differ — work and personal, say. They can share conventions and structure
  without sharing content, and moving a generalized insight between them
  deliberately is much easier than unpicking a vault that mixed everything
  from day one.
- **Remember it's markdown, not a database.** Anyone with read access to the
  synced folder, on any paired device, has the whole thing. Encrypt the disk if
  that matters.

## Housekeeping

The vault accumulates entropy like anything else — duplicated facts, stale
project-memory pointers, topic files that have grown into several unrelated
subtopics. We trigger cleanup with a short prompt when it feels due:

> "Should we clean up your brain?"

**That phrase has no special meaning to Claude by itself** — there's no
hook, no slash command, nothing hardcoded. It works only because the
checklist below is written down *in the vault*, in the conventions note from
[step 5](#5-write-down-the-conventions-inside-the-vault). Because that note is
linked from `index.md`, any session that's read the index knows it exists and
goes and reads it when the phrase — or anything like it — comes up. Skip that
step and the phrase is just words: a fresh session with no memory of this
conversation has no way to know what "clean up" means.

The checklist itself (already in
[`templates/vault-conventions.md`](templates/vault-conventions.md)) —

- Project memory in any working directory touched recently that duplicates
  something already in, or that belongs in, the vault — consolidate it
  using the same approach as the [seeding prompt](#6-seed-the-vault-with-your-first-memories)
  above, leaving a one-line pointer stub so old wikilinks still resolve.
- Vault files that have grown into multiple unrelated subtopics (candidates
  for splitting) vs. `index.md` lines that no longer describe their file
  accurately.
- Uncommitted changes or a messy history, if you version the vault with git.
- Stray `*.sync-conflict-*` files anywhere under the synced folder — a sign
  two writers edited the same file concurrently — resolved by merging into
  the canonical file and deleting the conflict copy.

Run it from Claude Code, since checking project memory across working
directories needs real filesystem access the vault alone doesn't give you.
And treat it as deliberately prompted, not scheduled — say so explicitly
in that note, or a session may assume it should run this on its own.

## Gotchas

- **Two writers, one file.** Claude Desktop (via MCP) and Claude Code (via
  filesystem) touching the same file within seconds of each other can
  produce Syncthing conflict copies. Resolve by merging content into the
  canonical file and deleting the conflict copy — check periodically for
  stray `*.sync-conflict-*` files.
- **Renames don't update wikilinks.** An OS-level rename/move (e.g. from
  Claude Code) won't update Obsidian's `[[wikilinks]]` elsewhere in the
  vault the way a rename from inside Obsidian's UI would.
- **GitOps double-ownership, if you deploy the hub via a GitOps tool.** If
  the sync hub's manifests live in a subdirectory that's *also* referenced
  by more than one parent Application/Kustomization, both can end up
  believing they own the same live resources, tripping shared-resource
  warnings and risking one pruning what the other created. Keep a
  service's manifests owned by exactly one parent.
- **Index quality matters more than volume.** Since only the index file is
  auto-loaded, a fact buried in a topic file with a vague index line is
  effectively unrecallable even though it's technically written down.
- **A read-only vault goes stale.** If nothing instructs Claude to *write*
  cross-cutting facts back to the vault, they keep landing in whatever
  project you were sitting in, and the vault quietly becomes a snapshot of
  whenever you last curated it by hand. That instruction belongs in both the
  hook and your `~/.claude/CLAUDE.md`.

## What's in this repo

```
README.md                            the pattern, and how to set it up
CLAUDE.md                            instructions for Claude Code in THIS repo -
                                     guide someone through the pattern, don't
                                     silently reconfigure their setup
examples/hooks/
  load-vault-index.sh                SessionStart hook: loads the vault index and
                                     tells Claude to write back to the vault
  settings.json.example              how to register it in ~/.claude/settings.json
templates/
  vault-conventions.md               the authoritative note that lives IN the vault:
                                     boundary rules, entry quality, housekeeping
  memory-index.md                    starter memory/index.md
  global-CLAUDE.md                   block for your own ~/.claude/CLAUDE.md
  project-memory-pointer.md          pointer block for an individual project
```

Everything in `templates/` and `examples/` is a starting point to copy and edit,
not a framework to install. Take the parts that fit how you already work.
