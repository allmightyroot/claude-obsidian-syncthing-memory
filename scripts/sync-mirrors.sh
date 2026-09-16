#!/bin/bash
# Pulls the latest main from the fetch remote (GitHub, once PRs merge there —
# see README "Contributing") and pushes it out to every configured push URL
# on `origin` (GitHub + GitLab + Bitbucket), so the mirrors never drift
# behind a merge that happened on the host review actually occurs on.
#
# Safe to run any time; a no-op if everything's already in sync.

set -euo pipefail

if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree isn't clean — commit or stash first." >&2
    exit 1
fi

current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "On branch '$current_branch', not 'main' — switch to main first." >&2
    exit 1
fi

git pull --ff-only
git push
