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

for repo in "${repos[@]}"; do
  for candidate in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
    if gh api "repos/$owner/$repo/contents/$candidate" --jq '.name' >/dev/null 2>&1; then
      echo "$repo: skipped, $candidate already exists"
      continue 2
    fi
  done

  branch=$(gh api "repos/$owner/$repo" --jq '.default_branch')
  gh api -X PUT "repos/$owner/$repo/contents/$file_path" \
    -f message="Add CODEOWNERS assigning reviews to @$assignee" \
    -f content="$(printf '%s' "$content" | base64 | tr -d '\n')" \
    -f branch="$branch" >/dev/null
  echo "$repo: created $file_path on $branch"
done
