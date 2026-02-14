#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[verify] ERROR: $1" >&2
  exit 1
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  fail "Not inside a Git repository."
fi

cd "$repo_root"

hooks_path="$(git config --get core.hooksPath || true)"
if [[ "$hooks_path" != ".githooks" ]]; then
  fail "core.hooksPath is '${hooks_path:-<unset>}' (expected '.githooks'). Run: npm run hooks:install"
fi

for required in ".githooks/pre-push" "scripts/pre-push-gate.sh"; do
  if [[ ! -x "$required" ]]; then
    fail "$required is not executable. Run: npm run hooks:install"
  fi
done

echo "[verify] Hook wiring is valid."
echo "[verify] Running local pre-push gate checks..."
bash scripts/pre-push-gate.sh --local
echo "[verify] Pre-push gates verified."
