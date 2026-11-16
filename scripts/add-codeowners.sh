#!/usr/bin/env bash
# Add a CODEOWNERS file to every public repository of the owner, assigning
# all paths to the owner account. Idempotent: repositories that already
# define a CODEOWNERS file (.github/, repo root, or docs/) are skipped.
#
# Usage:
#   ./scripts/add-codeowners.sh                 # all public, non-archived repos
#   ./scripts/add-codeowners.sh repo-a repo-b   # only the named repositories
#
# Environment overrides:
#   OWNER      account owning the repositories (default: koopycat)
#   ASSIGNEE   username listed as code owner (default: OWNER)
#   FILE_PATH  where to create the file (default: .github/CODEOWNERS)
set -euo pipefail

owner="${OWNER:-koopycat}"
assignee="${ASSIGNEE:-$owner}"
file_path="${FILE_PATH:-.github/CODEOWNERS}"
content=$'* @'"$assignee"$'\n'

if [ "$#" -gt 0 ]; then
  repos=("$@")
else
  mapfile -t repos < <(gh repo list "$owner" --limit 200 --json name,isPrivate,isArchived \
    --jq '.[] | select(.isPrivate == false and .isArchived == false) | .name')
fi

if [ "${#repos[@]}" -eq 0 ]; then
  echo "no public, non-archived repositories found for $owner" >&2
  exit 1
fi

for repo in "${repos[@]}"; do
  skipped=""
  for candidate in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
    if gh api "repos/$owner/$repo/contents/$candidate" --jq '.name' >/dev/null 2>&1; then
      skipped="$candidate"
      break
    fi
  done
  if [ -n "$skipped" ]; then
    echo "$repo: skipped, $skipped already exists"
    continue
  fi

  if ! branch=$(gh api "repos/$owner/$repo" --jq '.default_branch'); then
    echo "$repo: failed to read default branch" >&2
    continue
  fi
  if ! gh api -X PUT "repos/$owner/$repo/contents/$file_path" \
    -f message="Add CODEOWNERS assigning reviews to @$assignee" \
    -f content="$(printf '%s' "$content" | base64 | tr -d '\n')" \
    -f branch="$branch" >/dev/null; then
    echo "$repo: failed to create $file_path" >&2
    continue
  fi
  echo "$repo: created $file_path on $branch"
done
