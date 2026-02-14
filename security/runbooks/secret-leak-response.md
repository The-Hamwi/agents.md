# Secret Leak Response Runbook

Use this runbook when any secret may have been committed, pushed, logged, or shared.

## 1. Contain immediately

- Revoke or disable the exposed credential.
- Rotate credentials before cleanup if immediate revocation would cause outage.
- Pause affected automations if needed (CI jobs, deploy hooks, integrations).

## 2. Scope impact

- Identify where the secret appeared:
  - Working tree
  - Local commit history
  - Remote branches/PRs/tags/releases
  - CI logs or external logs
- Identify all systems/accounts that used the credential.

## 3. Eradicate from source control

- Remove the secret from current files.
- If pushed, rewrite history to remove the secret from prior commits and force-push with maintainer coordination.
- After rewriting, invalidate old clones/forks that still contain leaked history.

## 4. Rotate and restore safely

- Issue a new credential with least privilege.
- Update secret stores and deployment environments.
- Confirm all dependent services are healthy.

## 5. Verify and close

- Run gate checks:
  - `npm run prepush:check`
  - `npm run gate:verify`
- Confirm GitHub required status check `pre-push-gate` is enforced on protected branches.
- Document incident timeline, impact, and preventive actions.

## Incident checklist template

- Detection timestamp:
- Reporter:
- Exposed secret type:
- Affected systems:
- Containment completed at:
- Rotation completed at:
- Verification completed at:
- Follow-up actions:
