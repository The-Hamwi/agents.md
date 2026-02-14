# Defense-in-Depth Roadmap

This roadmap turns current baseline controls into a layered, auditable security program.

## Technical context

- Stack: Next.js + TypeScript + GitHub Actions.
- Current controls:
  - Local pre-push sanitization and quality gate (`scripts/pre-push-gate.sh`).
  - CI gate workflow (`.github/workflows/pre-push-gate-ci.yml`).
  - Security policy and runbooks (`SECURITY.md`, `security/` docs).
- Constraints:
  - Keep developer friction low.
  - Prioritize controls that measurably reduce secret exposure and insecure merges.

## Scope

- In:
  - Source-control protection, CI hardening, secret lifecycle controls, and verification drills.
  - Process controls for ownership, response time, and periodic validation.
- Out:
  - Runtime infrastructure redesign.
  - Enterprise-wide IAM redesign outside this repository.

## Success criteria (fully addressed)

- Protected branches require `pre-push-gate` and PR review with no bypass.
- Secret scanning and push protection are enabled at repo or org level.
- Security workflow actions are pinned and least-privileged permissions are enforced.
- `security/runbooks/secret-leak-response.md` is exercised via at least one tabletop simulation.
- Rotation inventory exists for all production credentials used by this project.
- Quarterly control verification cadence is scheduled and owned.

## 30/60/90 implementation plan

### Phase 1 (Days 0-30): Enforcement baseline

Owner: Repository Maintainers

Tasks:

- Enable branch protection/rulesets for `main`:
  - Require PR before merge.
  - Require status checks to pass.
  - Require `pre-push-gate`.
  - Require branch up-to-date before merge.
  - Disallow bypass for admins/maintainers if policy requires strict mode.
- Enable GitHub Secret Scanning and Push Protection for the repository/org.
- Add `CODEOWNERS` coverage for security-critical paths:
  - `.github/workflows/*`
  - `scripts/pre-push-gate.sh`
  - `SECURITY.md`
  - `security/**`

Validation evidence:

- Screenshot/export of active branch protection or ruleset.
- PR showing `pre-push-gate` required and passing.
- Security settings showing secret scanning/push protection enabled.
- CODEOWNERS review enforcement observed on test PR.

Exit criteria:

- A PR cannot merge to `main` without `pre-push-gate` and required reviews.
- At least one blocked push/PR scenario has been tested end to end.

### Phase 2 (Days 31-60): CI and supply chain hardening

Owner: Maintainers + Security Champion

Tasks:

- Pin GitHub Actions to immutable SHAs where feasible.
- Set explicit `permissions` in workflows to least privilege.
- Add dependency risk checks in CI (`npm audit --omit=dev` at minimum).
- Add a second detection layer for secrets in CI (for example a dedicated scan action).
- Ensure workflow changes require reviewer approval (via CODEOWNERS + branch protection).

Validation evidence:

- Workflow diffs showing pinned actions and reduced permissions.
- CI logs showing dependency and secret-scan stages.
- Attempted insecure workflow PR blocked by required reviews.

Exit criteria:

- All production workflows use explicit least-privilege permissions.
- Security checks are visible as separate CI statuses in PRs.

### Phase 3 (Days 61-90): Operational resilience

Owner: Security Champion + On-call Maintainers

Tasks:

- Create a credential inventory with owner, scope, expiration, and rotation interval.
- Define severity levels and SLA targets for leak response:
  - Sev1 leak: containment start <= 15 minutes.
  - Sev2 leak: containment start <= 4 hours.
- Run a tabletop leak simulation using `security/runbooks/secret-leak-response.md`.
- Add incident postmortem template and storage location.
- Add quarterly control review checklist and schedule.

Validation evidence:

- Credential inventory committed in private operations docs.
- Tabletop report with timeline and identified gaps.
- Calendar/task system entries for quarterly reviews.

Exit criteria:

- Team can execute leak containment and rotation without ad hoc decisions.
- Control verification is recurring, not one-time.

## Control matrix

| Layer | Control | Primary owner | Verification |
| --- | --- | --- | --- |
| Developer workstation | Local pre-push gate | Developer + Maintainers | `npm run prepush:check` |
| CI pipeline | `pre-push-gate` required check | Maintainers | Required status on PR |
| Repository governance | Branch protection/rulesets, CODEOWNERS | Maintainers | Ruleset/branch config + review logs |
| Secret prevention | Push protection + secret scanning | Security Champion | GitHub security dashboard |
| Incident response | Runbook + tabletop drill | Security Champion | Tabletop artifact + postmortem |
| Credential hygiene | Rotation policy and schedule | Service owners | Rotation logs + periodic audit |

## Risk register and mitigation

- Risk: Local hooks bypassed with `--no-verify`.
  - Mitigation: Required CI status checks and merge protection.
- Risk: New secret patterns evade regex checks.
  - Mitigation: Dedicated CI secret scanner + push protection.
- Risk: Workflow privilege creep over time.
  - Mitigation: CODEOWNERS + quarterly workflow permission review.
- Risk: Slow incident response due to unclear ownership.
  - Mitigation: Named owner roster + severity/SLA policy.

## Implementation backlog (suggested order)

- [ ] Configure branch protection/ruleset strict mode.
- [ ] Enable secret scanning and push protection.
- [x] Add `CODEOWNERS` for security-critical files.
- [x] Pin workflow actions and tighten permissions.
- [ ] Add dependency and secret CI check jobs.
- [ ] Create credential inventory and rotation calendar.
- [ ] Run one tabletop leak response drill.
- [ ] Capture postmortem template and review cadence.
