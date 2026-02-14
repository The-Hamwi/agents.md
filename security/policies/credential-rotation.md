# Credential Rotation Policy

This policy defines minimum requirements for rotating credentials used by this project.

## Policy requirements

- Every credential must have a named owner.
- Every credential must map to all consuming systems/services.
- Privilege scope must be least-privilege and reviewed during each rotation.
- Rotation cadence must be defined (time-based or event-driven).
- Emergency rotation must occur after any suspected exposure.

## Rotation checklist

For each rotated credential:

- Owner: person/team responsible for the credential.
- Systems: all apps/jobs/services using it.
- Scope: reduce permissions to minimum required.
- Expiry: set rotation window or expiration where supported.
- Rollout: update secrets in all environments (`dev`, `staging`, `prod`).
- Validation: verify auth flows and service health after rotation.
- Cleanup: remove deprecated credentials and backout tokens.

## Event-driven mandatory rotation triggers

- Secret appears in Git history, PR discussion, issue, or logs.
- Team member with credential access leaves role/team.
- Provider notifies compromise, abuse, or key misuse.
- Credential was shared through an unapproved channel.

## Evidence and audit

Store evidence for each rotation event:

- Rotation date/time
- Credential owner
- Systems updated
- Validation outcome
- Cleanup confirmation
