# Security Policy

This project treats accidental secret exposure as a security incident.

## Reporting a security issue

- Do not open a public issue with sensitive details.
- Use GitHub Security Advisories for private reporting:
  - Repo `Security` tab -> `Advisories` -> `Report a vulnerability`.
- If the issue is an exposed credential, start containment immediately (revoke/rotate first, then report).

## Secrets handling rules

- Never commit real secrets, tokens, passwords, API keys, private keys, or `.env` files.
- Allowed templates: `.env.example`, `.env.sample`, `.env.template`.
- Store runtime secrets in your hosting platform or cloud secret manager, not in Git.

## Security documentation

- Security docs index: `security/README.md`
- GitHub branch protection setup: `security/runbooks/github-branch-protection-setup.md`
- Secret leak response runbook: `security/runbooks/secret-leak-response.md`
- Credential rotation policy: `security/policies/credential-rotation.md`
- Defense-in-depth roadmap: `security/roadmaps/defense-in-depth-roadmap.md`

## Defense in depth baseline

- Local prevention: Git pre-push gate (`scripts/pre-push-gate.sh`).
- CI enforcement: required `pre-push-gate` GitHub Actions check.
- Repository controls: branch protection/rulesets, required reviews, and no bypass for protected branches.
