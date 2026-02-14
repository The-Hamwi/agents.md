# GitHub Branch Protection Setup

This runbook configures branch protection to enforce:

- Pull-request reviews
- Code Owner reviews
- Required status check: `pre-push-gate`

## Prerequisites

- GitHub CLI installed (`gh`).
- Authenticated GitHub CLI token with repo admin/maintain access.
- Existing workflow check named `pre-push-gate` in this repository.

## Automated setup (recommended)

Dry run:

```bash
bash scripts/configure-branch-protection.sh --repo <owner>/<repo>
```

Apply:

```bash
bash scripts/configure-branch-protection.sh --repo <owner>/<repo> --apply
```

Optional flags:

- `--branch <name>` (default `main`)
- `--check <status-check-name>` (default `pre-push-gate`)
- `--approvals <n>` (default `1`)

## Manual setup in GitHub UI

1. Open repository `Settings` -> `Branches`.
2. Edit branch protection rule for `main` (or create one).
3. Enable:
   - Require a pull request before merging.
   - Require approvals (set count per policy).
   - Require review from Code Owners.
   - Require status checks to pass before merging.
   - Add `pre-push-gate` as required check.
   - Require branches to be up to date before merging.
   - (Optional strict mode) Do not allow bypassing above settings.

## Verification

- Open a PR that changes `security/**` or `.github/workflows/*`.
- Confirm Code Owner review is requested and required.
- Confirm `pre-push-gate` appears as required and must pass before merge.
