#!/bin/sh
# The copy of a run: sh graph/copy.sh <workspace> <branch>, from the group folder; step 1 of
# the path calls it. It makes an isolated clone of the repository at <workspace>, as ATM does
# for every run: its own .git, the last commit of the folder it was called from, and the
# branch <branch>, which lives only in the clone. The repository it came from gets no branch
# and no worktree, so no other run, session or copy of it ever meets this run's branch. The
# clone's origin is the repository's origin: step 5 pushes the branch where the pull request
# opens. The run starts from the last commit: what is not committed is not in the copy.
set -eu
workspace=${1:?usage: sh graph/copy.sh <workspace> <branch>}
branch=${2:?usage: sh graph/copy.sh <workspace> <branch>}
if [ -e "$workspace" ]; then
  printf 'red: %s already exists\n' "$workspace"
  exit 1
fi
top=$(git rev-parse --show-toplevel)
sha=$(git rev-parse HEAD)
git clone -q --local --no-checkout "$top" "$workspace"
git -C "$workspace" checkout -q -b "$branch" "$sha"
if origin=$(git remote get-url origin 2> /dev/null); then
  git -C "$workspace" remote set-url origin "$origin"
fi
printf 'copy: %s, a clone at %s on its own branch %s\n' "$workspace" "$(git rev-parse --short HEAD)" "$branch"
