<div align="center">

# koopycat / GitHub Actions

### Less PR housekeeping. One place to maintain it.

Reusable workflows for the repositories you look after. Start with automatic PR
assignment: a small caller file, your repository's built-in token, and no manual
trip to the Assignees sidebar.

[Get started](#quick-start) · [Workflows](#workflows) · [Security](#security-by-design)

</div>

---

## Your workflow, without the copy-paste maintenance

- **Keep the logic in one place.** Repositories call a shared, versioned workflow
  instead of carrying their own assignment scripts.
- **Use it in public or private repositories.** No CODEOWNERS feature or paid
  GitHub plan required; normal Actions usage limits still apply.
- **Skip the extra credentials.** The calling repository's `GITHUB_TOKEN` handles
  assignment. No personal access token, app installation, or inherited secrets.
- **Leave the code alone.** The assignment job updates PR metadata. It never
  checks out, builds, or executes code from the pull request.

## Workflows

| Workflow | What it does | Default |
| --- | --- | --- |
| [Assign pull request](.github/workflows/assign-pr.yml) | Adds an assignee when your caller receives a PR event; keeps existing assignees. | `koopycat` |

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
    uses: koopycat/github-actions/.github/workflows/assign-pr.yml@v1
```

Open a pull request. `koopycat` will appear under **Assignees** once the workflow
finishes. This repository [uses the workflow itself](.github/workflows/auto-assign.yml).

> Each repository needs this caller file. Publishing a shared workflow does not
> automatically enable it across your account.

## Make it yours

To use a different assignee, add `with` to the `assign` job above:

```yaml
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

The reusable workflow receives the **caller's repository context and token**, not
access to every repository on your account. It requests only `pull-requests: write`
and needs no source checkout or third-party action dependency. Calling this public
workflow does not make a private repository or its source code public.

> **Keep this workflow metadata-only.** `pull_request_target` can grant write
> access even for fork PRs. Do not add untrusted PR checkout, build commands,
> scripts, or downloaded PR artifacts to the privileged job.

Actions must be enabled in the caller, and its Actions policies must allow this
reusable workflow. Private repositories use the caller's GitHub Actions allowance.

## Choose your update policy

Use **`@v1`** to receive compatible updates without changing each caller. For an
immutable dependency, replace `@v1` with the full commit SHA behind the
[`v1` tag](https://github.com/koopycat/github-actions/releases/tag/v1). GitHub resolves
and runs that exact workflow revision.

## Under the hood

One GitHub-hosted job calls the
[assignee API](https://docs.github.com/en/rest/issues/assignees#add-assignees-to-an-issue)
using the preinstalled GitHub CLI, then checks the returned assignee list. GitHub
manages PR assignees through the Issues API; no issue is created by this workflow.

For the platform details, see GitHub's guides to
[reusing workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
and [securely using `pull_request_target`](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target).
