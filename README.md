<div align="center">

# koopycat / GitHub Actions

### Less PR housekeeping. One place to maintain it.

Reusable actions for the repositories you look after. Start with automatic PR
assignment: add one action step and use your repository's built-in token instead
of assigning each pull request by hand.

[Get started](#quick-start) · [Actions](#actions) · [Security](#security-by-design)

</div>

---

## Your workflow, without the copy-paste maintenance

- **Keep the logic in one place.** Repositories use a shared, versioned action
  instead of carrying their own assignment scripts.
- **Use it in public or private repositories.** No CODEOWNERS feature or paid
  GitHub plan required; normal Actions usage limits still apply.
- **Skip the extra credentials.** The calling repository's `GITHUB_TOKEN` handles
  assignment. No personal access token, app installation, or inherited secrets.
- **Leave the code alone.** The assignment job updates PR metadata. It never
  checks out, builds, or executes code from the pull request.

## Actions

| Action | What it does | Default |
| --- | --- | --- |
| [Assign pull request](assign-pr/action.yml) | Adds an assignee when your workflow receives a PR event; keeps existing assignees. | `koopycat` |

## Quick start

Add `.github/workflows/auto-assign.yml` to the **default branch** of any repository
you want to enable:

```yaml
name: Auto-assign pull requests

on:
  pull_request_target:
    types: [opened, reopened]

permissions:
  pull-requests: write

jobs:
  assign:
    runs-on: ubuntu-latest
    steps:
      - uses: koopycat/github-actions/assign-pr@v2
```

Open a pull request. `koopycat` will appear under **Assignees** once the workflow
finishes. This repository [uses the action itself](.github/workflows/auto-assign.yml),
referencing `@main` so its PRs exercise the current implementation.

> Each repository needs this workflow file. Publishing a shared action does not
> automatically enable it across your account. No checkout step is required.

## Make it yours

To use a different assignee, add `with` to the action step:

```yaml
      - uses: koopycat/github-actions/assign-pr@v2
        with:
          assignee: YOUR_USERNAME
```

| Input | Default | Accepted value |
| --- | --- | --- |
| `assignee` | `koopycat` | One GitHub username without `@`, assignable in the calling repository. |

### What to expect

- **New and reopened PRs:** assigned with the caller shown above.
- **Drafts and self-authored PRs:** included, with no author exclusion.
- **Fork PRs:** supported through `pull_request_target`.
- **Existing assignees:** preserved; the workflow adds rather than replaces.
- **Already-open PRs:** not backfilled. Reopen a PR to trigger the workflow.
- **Unsuccessful assignment:** the job fails if the API response does not include
  the requested assignee, even if GitHub silently ignores the request.

PRs created or reopened by another workflow using `GITHUB_TOKEN` do not trigger
this assignment workflow. If that automation needs to trigger assignment, use a
GitHub App token or a personal access token to create or reopen the PR. See
[GitHub's event restrictions](https://docs.github.com/en/actions/concepts/security/github_token#when-github_token-triggers-workflow-runs).

This is **assignment**, not a review request or a merge-approval requirement.

## Security by design

The action uses the caller's repository context and token, not access to every
repository on your account. Grant `pull-requests: write` in the calling workflow;
an action cannot set its own token permissions. The action does not check out
source code or depend on other actions. Using this public action does not make
a private repository or its source code public.

> **Keep this workflow metadata-only.** `pull_request_target` can grant write
> access even for fork PRs. Do not add untrusted PR checkout, build commands,
> scripts, or downloaded PR artifacts to the privileged job.

Actions must be enabled in the caller, and its Actions policies must allow this
action. Private repositories use the caller's GitHub Actions allowance.

The example uses `ubuntu-latest`, which includes Bash, GitHub CLI (`gh`), and `jq`.
Other runners must provide these tools. The action runs within the caller's job;
the caller chooses the runner and any job timeout.

## Choose your update policy

Use `@v2` to receive compatible updates without changing each caller. For an
immutable dependency, replace `@v2` with the full commit SHA behind the
[`v2` tag](https://github.com/koopycat/github-actions/releases/tag/v2). GitHub resolves
and runs that exact action revision.

When upgrading from `v1`, replace the job-level reusable workflow call with
`runs-on` and an action step as shown in the quick start. Move any `assignee`
input to that step's `with` block. The existing `v1` tag remains unchanged;
the reusable workflow is no longer present on `main` or in `v2`.

## Under the hood

The composite action calls the
[assignee API](https://docs.github.com/en/rest/issues/assignees#add-assignees-to-an-issue)
using GitHub CLI, then checks the returned assignee list with `jq`. GitHub manages
PR assignees through the Issues API; the action does not create an issue.

For the platform details, see GitHub's guides to
[composite actions](https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action)
and [securely using `pull_request_target`](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target).
