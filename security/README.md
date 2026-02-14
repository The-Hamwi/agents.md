# Security Docs

This directory contains operational security documentation for this repository.

## Document map

- Policy entrypoint (public): `../SECURITY.md`
- GitHub branch protection setup: `runbooks/github-branch-protection-setup.md`
- Secret leak response runbook: `runbooks/secret-leak-response.md`
- Credential rotation policy: `policies/credential-rotation.md`
- Defense-in-depth roadmap: `roadmaps/defense-in-depth-roadmap.md`

## Current enforced controls

- Local pre-push sanitization gate: `scripts/pre-push-gate.sh`
- CI gate workflow: `.github/workflows/pre-push-gate-ci.yml`
- Repository governance target: required `pre-push-gate` status check on protected branches

## Maintenance rule

Update these documents whenever security controls, incident handling, or credential lifecycle requirements change.
