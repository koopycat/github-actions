#!/usr/bin/env bash
# Add a request-review workflow to every private, non-archived repository of
# the owner. CODEOWNERS review requests do not fire in private repositories
# on a free personal account; this workflow requests the owner as reviewer
# through the API instead. Idempotent: repositories that already have the
# workflow file are skipped.
#
# GitHub rejects review requests addressed to the pull request author, so
# self-authored pull requests are skipped by the action; bot- and
# collaborator-authored pull requests get the review request.
#
# Usage:
#   ./scripts/add-request-review.sh                 # all private, non-archived repos
#   ./scripts/add-request-review.sh repo-a repo-b   # only the named repositories
#
# Environment overrides:
#   OWNER        account owning the repositories (default: koopycat)
#   REVIEWER     username to request reviews from (default: OWNER)
#   FILE_PATH    where to create the workflow (default: .github/workflows/request-review.yml)
#   ACTION_REF   version of the action to reference (default: v2.1.0)
set -euo pipefail

owner="${OWNER:-koopycat}"
reviewer="${REVIEWER:-$owner}"
file_path="${FILE_PATH:-.github/workflows/request-review.yml}"
action_ref="${ACTION_REF:-v2.1.0}"

content=$(cat <<EOF
name: Request review on pull requests

on:
  pull_request_target:
    types: [opened, reopened]

permissions:
  pull-requests: write

jobs:
  request-review:
    runs-on: ubuntu-latest
    steps:
      - uses: $owner/github-actions/request-review@$action_ref
EOF
)

if [ "$#" -gt 0 ]; then
  repos=("$@")
else
  filter='.[] | select(.isArchived == false and .isFork == false and .isPrivate == true) | .name'
  mapfile -t repos < <(gh repo list "$owner" --limit 200 --json name,isPrivate,isArchived,isFork --jq "$filter")
fi

if [ "${#repos[@]}" -eq 0 ]; then
  echo "no private, non-archived repositories selected for $owner" >&2
  exit 1
fi

for repo in "${repos[@]}"; do
  if gh api "repos/$owner/$repo/contents/$file_path" --jq '.name' >/dev/null 2>&1; then
    echo "$repo: skipped, $file_path already exists"
    continue
  fi

  if ! branch=$(gh api "repos/$owner/$repo" --jq '.default_branch'); then
    echo "$repo: failed to read default branch" >&2
    continue
  fi
  if ! gh api -X PUT "repos/$owner/$repo/contents/$file_path" \
    -f message="Request review from @$reviewer on pull requests" \
    -f content="$(printf '%s' "$content" | base64 | tr -d '\n')" \
    -f branch="$branch" >/dev/null; then
    echo "$repo: failed to create $file_path" >&2
    continue
  fi
  echo "$repo: created $file_path on $branch"
done
