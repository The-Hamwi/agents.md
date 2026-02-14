#!/usr/bin/env bash
set -euo pipefail

HOOK_PATH=".githooks"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "[hooks] Not inside a git repository. Skipping hook installation."
  exit 0
fi

cd "$repo_root"

if [[ ! -f "${HOOK_PATH}/pre-push" ]]; then
  echo "[hooks] Missing ${HOOK_PATH}/pre-push. Cannot install hooks." >&2
  exit 1
fi

git config core.hooksPath "$HOOK_PATH"

chmod +x "${HOOK_PATH}/pre-push"
chmod +x "scripts/pre-push-gate.sh"
chmod +x "scripts/setup-hooks.sh"
if [[ -f "scripts/verify-gates.sh" ]]; then
  chmod +x "scripts/verify-gates.sh"
fi

echo "[hooks] Installed pre-push gate via core.hooksPath=${HOOK_PATH}"
