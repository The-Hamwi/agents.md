#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/configure-branch-protection.sh [--repo owner/name] [--branch main] [--check pre-push-gate] [--approvals 1] [--apply]

Defaults:
  --branch main
  --check pre-push-gate
  --approvals 1
  dry-run mode (no changes) unless --apply is passed

Examples:
  bash scripts/configure-branch-protection.sh --repo my-org/my-repo
  bash scripts/configure-branch-protection.sh --repo my-org/my-repo --apply
EOF
}

fail() {
  echo "[branch-protection] ERROR: $1" >&2
  exit 1
}

require_tool() {
  local tool="$1"
  command -v "$tool" >/dev/null 2>&1 || fail "Missing required tool: $tool"
}

infer_repo_from_origin() {
  local url repo
  url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    return 1
  fi
  repo="$(echo "$url" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
  if [[ "$repo" =~ ^[^/]+/[^/]+$ ]]; then
    echo "$repo"
    return 0
  fi
  return 1
}

REPO=""
BRANCH="main"
CHECK_NAME="pre-push-gate"
APPROVALS="1"
APPLY="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -lt 2 ]] && fail "--repo requires owner/name"
      REPO="$2"
      shift 2
      ;;
    --branch)
      [[ $# -lt 2 ]] && fail "--branch requires a value"
      BRANCH="$2"
      shift 2
      ;;
    --check)
      [[ $# -lt 2 ]] && fail "--check requires a value"
      CHECK_NAME="$2"
      shift 2
      ;;
    --approvals)
      [[ $# -lt 2 ]] && fail "--approvals requires a value"
      APPROVALS="$2"
      shift 2
      ;;
    --apply)
      APPLY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

if [[ -z "$REPO" ]]; then
  REPO="$(infer_repo_from_origin || true)"
fi
[[ -z "$REPO" ]] && fail "Could not infer repo. Pass --repo owner/name."

if ! [[ "$APPROVALS" =~ ^[0-9]+$ ]]; then
  fail "--approvals must be an integer"
fi

require_tool gh
require_tool git

if ! gh auth status -h github.com >/dev/null 2>&1; then
  fail "GitHub CLI is not authenticated. Run: gh auth login -h github.com"
fi

permission="$(gh repo view "$REPO" --json viewerPermission --jq .viewerPermission)"
echo "[branch-protection] Repo: $REPO"
echo "[branch-protection] Viewer permission: $permission"

if [[ "$permission" != "ADMIN" && "$permission" != "MAINTAIN" ]]; then
  echo "[branch-protection] WARNING: You likely need ADMIN or MAINTAIN permission to update branch protection."
fi

payload="$(mktemp)"
cleanup() {
  rm -f "$payload"
}
trap cleanup EXIT

cat > "$payload" <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["$CHECK_NAME"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": $APPROVALS,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
EOF

if [[ "$APPLY" != "true" ]]; then
  echo "[branch-protection] Dry run only. Payload that would be applied:"
  cat "$payload"
  echo "[branch-protection] To apply, re-run with --apply"
  exit 0
fi

echo "[branch-protection] Applying protection to $REPO branch $BRANCH ..."
gh api \
  --method PUT \
  "repos/$REPO/branches/$BRANCH/protection" \
  -H "Accept: application/vnd.github+json" \
  --input "$payload" >/dev/null

echo "[branch-protection] Applied. Verifying ..."
gh api "repos/$REPO/branches/$BRANCH/protection" --jq '.required_pull_request_reviews.require_code_owner_reviews, .required_status_checks.contexts'
echo "[branch-protection] Done."
