# GitHub Actions

Reusable GitHub Actions workflows for koopycat repositories. This repository is
public so both public and private repositories can call its workflows.

## Automatically assign pull requests

Add `.github/workflows/auto-assign.yml` to the default branch of each repository:

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

New and reopened pull requests are assigned to `koopycat`, including drafts,
fork pull requests, and pull requests authored by the assignee. Existing assignees
are preserved. Already-open pull requests are not backfilled; reopening one
triggers assignment.

The caller must run on a pull request event and grant `pull-requests: write`.
`pull_request_target` supports fork pull requests without a personal access token.
The reusable workflow automatically uses the calling repository's `GITHUB_TOKEN`.
No secrets need to be configured or inherited. The workflow checks the API response
and fails if the requested assignee was not added.

### Inputs

| Input | Default | Meaning |
| --- | --- | --- |
| `assignee` | `koopycat` | One GitHub username, without `@`; must be assignable in the calling repository. |

To choose a different assignee, add `with` to the calling job:

```yaml
jobs:
  assign:
    uses: koopycat/github-actions/.github/workflows/assign-pr.yml@v1
    with:
      assignee: YOUR_USERNAME
```

Keep the trigger and permissions from the complete example above.

### Security and access

- This workflow updates PR metadata only. It does not check out or execute PR code.
  Do not add untrusted PR checkout, builds, scripts, or artifacts to this privileged
  workflow: `pull_request_target` can have write access even for fork PRs.
- Actions must be enabled in the calling repository, and its Actions policies must
  allow this reusable workflow.
- Private callers do not publish their source code by calling a public workflow.
  The job runs in the caller's context, with the caller's repository-scoped token.
- No CODEOWNERS feature or paid GitHub plan is required. GitHub-hosted runner usage
  in private repositories counts against the caller's Actions allowance.
- `v1` is the compatible major-version reference. For an immutable dependency,
  replace `@v1` with the full commit SHA behind that tag.

### Rollout

Each repository needs its own caller file. Placing a workflow in this repository
or in `koopycat/.github` does not enable it across all repositories automatically.
The caller does not request reviews or enforce merge approval; it only adds an
assignee. This repository uses the same reusable workflow for its own pull requests.

## References

- [Reusing workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [Securely using pull_request_target](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target)
- [Assignee API](https://docs.github.com/en/rest/issues/assignees#add-assignees-to-an-issue)
