#!/bin/bash
# SessionStart hook: load the shared memory vault's index into every Claude Code
# session, in every project, and tell Claude to write cross-cutting facts back to
# the vault instead of burying them in one project's local memory.
#
# Install: copy to ~/.claude/hooks/load-vault-index.sh, chmod +x, and register it
# in ~/.claude/settings.json (see settings.json.example next to this file).
#
# Requires: jq (for safe JSON encoding of arbitrary markdown).

# The vault lands at a different path on each machine depending on how the sync
# client is configured (a Linux box's system path vs. a Mac's Syncthing folder),
# and this hook runs everywhere. Probe known locations and exit quietly if the
# vault isn't on this host at all - a missing vault is not an error.
CANDIDATES=(
  "$HOME/Sync/myvault/memory"
  "$HOME/Syncthing/myvault/memory"
  "$HOME/myvault/memory"
  "/data/syncthing/myvault/memory"
)

VAULT_DIR=""
for candidate in "${CANDIDATES[@]}"; do
  if [ -f "$candidate/index.md" ]; then
    VAULT_DIR="$candidate"
    break
  fi
done

if [ -z "$VAULT_DIR" ]; then
  exit 0
fi

index_content=$(cat "$VAULT_DIR/index.md")

# Only the index is injected, every session, in every project. Topic files are
# read on demand - which is why each index line has to be descriptive enough to
# tell a session with zero other context whether that file is worth opening.
#
# To inject a second always-loaded file (e.g. a cross-repo map of what each of
# your projects does), read it the same way and concatenate it into the string
# below. Keep that list very short: everything here costs context in every single
# session, whether it turns out to be relevant or not.

jq -n --arg index "$index_content" --arg dir "$VAULT_DIR" '{
  systemMessage: "Shared memory vault index loaded.",
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: (
      "The following is index.md from a shared memory vault (plain markdown, synced across this user'"'"'s devices) located at " + $dir + ". It is the canonical source for cross-cutting facts about this user - preferences, standards, infrastructure, working style - as opposed to this project'"'"'s own local memory.\n\n"
      + $index
      + "\n\nHow to use it:\n"
      + "- Read the relevant topic file from that directory when something it covers comes up. Only this index is loaded automatically; the topic files are not.\n"
      + "- When you learn something durable and cross-cutting (a standing preference, a standard, a fact about this user or their infrastructure rather than about this one repo), write it into the appropriate topic file in that vault directory - creating a new topic file with frontmatter and an index.md line if nothing fits - rather than duplicating it into this project'"'"'s local memory.\n"
      + "- Keep project-specific memory (this repo'"'"'s incidents, quirks with no reuse value elsewhere) in this project'"'"'s own memory, not the vault.\n"
      + "- Never write credentials, tokens, or keys into the vault; it replicates to every synced device and into backups."
    )
  }
}'
