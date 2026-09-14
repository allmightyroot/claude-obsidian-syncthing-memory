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

Three pieces, each doing one job:

1. **Obsidian vault** — a folder of plain Markdown files. This is the actual
   memory; Obsidian itself is just one of several front ends onto it.
2. **Syncthing** — a peer-to-peer, self-hosted file-sync mesh (not Obsidian
   Sync, which is a paid subscription service). One node runs in Kubernetes
   as an always-on sync hub; other nodes (laptops, other servers) sync into
   the same folder over the Syncthing protocol.
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
duplicating vault content:

```markdown
## Shared memory
Cross-cutting facts about you, your standards, and infrastructure live in the
Obsidian vault, not here — see memory/index.md in the vault (synced via
Syncthing, mounted at /path/to/vault on the hosts that need it).
Read that first. Only project-specific memory for *this* repo belongs below.
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

### 1. Deploy Syncthing as an always-on hub

Run Syncthing somewhere that's always reachable — a Kubernetes cluster, a
home server, whatever you've already got. Genericized example manifests
(originally an ArgoCD-managed Deployment on a small k3s homelab cluster,
fronted by a private overlay-network ingress) are in [`examples/k8s/`](examples/k8s/):

- `namespace.yaml`, `pvc.yaml` — namespace + persistent storage for
  Syncthing's config and the synced folder
- `deployment.yaml` — the Syncthing container itself, plus an optional
  restic sidecar that backs up the vault on a timer, independent of
  Syncthing's own sync state
- `service.yaml`, `ingress.yaml`, `sync-loadbalancer.yaml` — expose the GUI
  over HTTPS and the raw sync protocol (TCP/UDP 22000) over your private
  network

Key details worth knowing before you copy these:

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
as context at the start of every session. This is what makes cross-cutting
facts available everywhere without Claude Code needing to know to go look
for them.

Claude Code needs no plugin here — it reads/writes the vault's Markdown
files as a normal filesystem path, same as any other file in a project.

### 5. Seed the vault with your first memories

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
  file if nothing existing fits, linked from index.md), then remove it
  from the project file.
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

### 6. Exclude version-control internals from the sync, if you version the vault

If you `git init` the vault for real history/rollback, exclude `.git/` from
Syncthing's sync (via `.stignore`) rather than letting Syncthing sync it —
git's internal files (index, refs, `HEAD`) aren't safe under
concurrent-writer sync the way plain Markdown is, especially when more than
one machine in the mesh might run git against the same working copy.
`.gitignore` inside the vault should separately exclude Obsidian's own
workspace-state directory and any plugin installer artifacts — churn, not
vault content.

Habit: after editing anything under the vault in a session, commit before
finishing up. This captures your own edits plus whatever the other
integration wrote since the last commit — writes from the other side land
as plain file changes via Syncthing, so git only sees them at the next
commit, not live.

### 7. Back it up

Point a backup job at the vault's on-disk sync target independent of
Syncthing itself — Syncthing replicates state, it doesn't protect against
deleting or corrupting a file, since deletions replicate too. The example
Deployment includes a `restic` sidecar that snapshots the vault directory
on a timer with retention (e.g. keep 7 daily / 4 weekly / 6 monthly) and
posts a pass/fail notification to a chat webhook on each run.

## Housekeeping

The vault accumulates entropy like anything else — duplicated facts, stale
project-memory pointers, topic files that have grown into several unrelated
subtopics. Rather than running cleanup automatically, prompt it explicitly
when it feels due, e.g.:

> "Should we clean up your brain?"

Run this from Claude Code, since it needs to check project memory across
working directories, not just the vault itself. When it runs, it should
check:

- Project memory in any working directory touched recently that duplicates
  something already in, or that belongs in, the vault — consolidate it
  using the same approach as the [seeding prompt](#5-seed-the-vault-with-your-first-memories)
  above, leaving a one-line pointer stub so old wikilinks still resolve.
- Vault files that have grown into multiple unrelated subtopics (candidates
  for splitting) vs. `index.md` lines that no longer describe their file
  accurately.
- Uncommitted changes or a messy history, if you version the vault with git.
- Stray `*.sync-conflict-*` files anywhere under the synced folder — a sign
  two writers edited the same file concurrently — resolved by merging into
  the canonical file and deleting the conflict copy.

This is deliberately a prompted activity, not a background job — nothing
runs it unless you ask.

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

## Repo layout

```
README.md            # this file
examples/k8s/         # genericized Kubernetes manifests for the sync hub
```
