#!/usr/bin/env bash
set -euo pipefail

GATE_NAME="pre-push-gate"
ZERO_SHA="0000000000000000000000000000000000000000"

usage() {
  cat <<'EOF'
Usage:
  scripts/pre-push-gate.sh [remote-name remote-url]
  scripts/pre-push-gate.sh --local
  scripts/pre-push-gate.sh --range <commit-range>

Modes:
  hook mode (default) reads refs from stdin (Git pre-push contract).
  --local scans @{upstream}..HEAD (or latest commit if no upstream).
  --range scans an explicit git diff range.
EOF
}

log() {
  printf '[%s] %s\n' "$GATE_NAME" "$1"
}

error() {
  printf '[%s] ERROR: %s\n' "$GATE_NAME" "$1" >&2
}

fail() {
  error "$1"
  exit 1
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    fail "Required tool '$tool' was not found."
  fi
}

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  fail "Not inside a Git repository."
fi
cd "$repo_root"

require_tool git
require_tool node
require_tool npm

mode="hook"
manual_range=""
remote_name=""
remote_url=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)
      mode="local"
      shift
      ;;
    --range)
      [[ $# -lt 2 ]] && fail "--range requires a value."
      mode="range"
      manual_range="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$remote_name" ]]; then
        remote_name="$1"
      elif [[ -z "$remote_url" ]]; then
        remote_url="$1"
      fi
      shift
      ;;
  esac
done

empty_tree_sha="$(git hash-object -t tree /dev/null)"

single_commit_range() {
  local sha="$1"
  local parent
  parent="$(git rev-parse --verify --quiet "${sha}^" 2>/dev/null || true)"
  if [[ -n "$parent" ]]; then
    printf '%s..%s\n' "$parent" "$sha"
  else
    printf '%s..%s\n' "$empty_tree_sha" "$sha"
  fi
}

range_for_new_branch() {
  local local_sha="$1"
  local branch_remote="$2"
  local remote_head=""
  local base=""

  if [[ -n "$branch_remote" ]]; then
    remote_head="$(git symbolic-ref --quiet --short "refs/remotes/${branch_remote}/HEAD" 2>/dev/null || true)"
  fi
  if [[ -z "$remote_head" ]]; then
    remote_head="$(git symbolic-ref --quiet --short "refs/remotes/origin/HEAD" 2>/dev/null || true)"
  fi

  if [[ -n "$remote_head" ]]; then
    base="$(git merge-base "$local_sha" "$remote_head" 2>/dev/null || true)"
    if [[ -n "$base" ]]; then
      printf '%s..%s\n' "$base" "$local_sha"
      return
    fi
  fi

  single_commit_range "$local_sha"
}

declare -A seen_ranges=()
declare -a ranges=()

add_range() {
  local value="$1"
  if [[ -z "$value" ]]; then
    return
  fi
  if [[ -z "${seen_ranges[$value]+x}" ]]; then
    ranges+=("$value")
    seen_ranges["$value"]=1
  fi
}

if [[ "$mode" == "range" ]]; then
  add_range "$manual_range"
elif [[ "$mode" == "local" ]]; then
  if git rev-parse --verify --quiet "@{upstream}" >/dev/null; then
    add_range "@{upstream}..HEAD"
  elif git rev-parse --verify --quiet HEAD >/dev/null; then
    add_range "$(single_commit_range "HEAD")"
  fi
else
  while IFS=' ' read -r _local_ref local_sha _remote_ref remote_sha; do
    [[ -z "${local_sha:-}" ]] && continue
    [[ "$local_sha" == "$ZERO_SHA" ]] && continue

    if [[ "$remote_sha" == "$ZERO_SHA" ]]; then
      add_range "$(range_for_new_branch "$local_sha" "$remote_name")"
    else
      add_range "${remote_sha}..${local_sha}"
    fi
  done
fi

if [[ ${#ranges[@]} -eq 0 ]]; then
  log "No commits to evaluate for this push."
  exit 0
fi

log "Evaluating commit range(s): ${ranges[*]}"

declare -A seen_files=()
declare -a changed_files=()

for range in "${ranges[@]}"; do
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ -z "${seen_files[$path]+x}" ]]; then
      changed_files+=("$path")
      seen_files["$path"]=1
    fi
  done < <(git diff --name-only --diff-filter=ACMRT "$range" --)
done

is_allowed_env_template() {
  local path="$1"
  case "$path" in
    *.env.example|*.env.sample|*.env.template|*.env.local.example|*.env.development.example|*.env.production.example)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_sensitive_path() {
  local path="$1"
  if [[ "$path" =~ (^|/)\.env([.][^/]+)?$ ]]; then
    if is_allowed_env_template "$path"; then
      return 1
    fi
    return 0
  fi
  if [[ "$path" =~ (^|/)\.envrc$ ]]; then
    return 0
  fi
  if [[ "$path" =~ \.(pem|key|p12|pfx|jks|keystore|der)$ ]]; then
    return 0
  fi
  if [[ "$path" =~ (^|/)(id_rsa|id_dsa|id_ecdsa|id_ed25519)$ ]]; then
    return 0
  fi
  return 1
}

declare -A finding_seen=()
declare -a path_findings=()
declare -a content_findings=()

record_path_finding() {
  local path="$1"
  local reason="$2"
  local key="path|${path}|${reason}"
  if [[ -z "${finding_seen[$key]+x}" ]]; then
    finding_seen["$key"]=1
    path_findings+=("${path}||${reason}")
  fi
}

record_content_finding() {
  local path="$1"
  local line="$2"
  local reason="$3"
  local key="content|${path}|${line}|${reason}"
  if [[ -z "${finding_seen[$key]+x}" ]]; then
    finding_seen["$key"]=1
    content_findings+=("${path}|${line}|${reason}")
  fi
}

for path in "${changed_files[@]}"; do
  if is_sensitive_path "$path"; then
    record_path_finding "$path" "Sensitive file path"
  fi
done

PATTERN_NAMES=(
  "AWS access key"
  "AWS temporary access key"
  "GitHub token"
  "GitHub fine-grained token"
  "Google API key"
  "Slack token"
  "Private key material"
  "JWT-like credential"
  "Credential assignment"
  "Credential in URL"
)

PATTERN_REGEXES=(
  'AKIA[0-9A-Z]{16}'
  'ASIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9_]{30,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'AIza[0-9A-Za-z_-]{35}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '-----BEGIN ([A-Z ]+)?PRIVATE KEY-----'
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9._-]{10,}\.[A-Za-z0-9._-]{10,}'
  "(api[_-]?key|client[_-]?secret|token|password|passwd|secret)[[:space:]]*[:=][[:space:]]*['\"][^'\"]{12,}['\"]"
  'https?://[^[:space:]/]+:[^[:space:]@]+@'
)

scan_range_for_content_findings() {
  local range="$1"
  local current_file=""
  local new_line=0
  local patch_line=""

  while IFS= read -r patch_line; do
    if [[ "$patch_line" == "+++ /dev/null" ]]; then
      current_file=""
      continue
    fi
    if [[ "$patch_line" == "+++ b/"* ]]; then
      current_file="${patch_line#+++ b/}"
      continue
    fi
    if [[ "$patch_line" == "@@ "* ]]; then
      if [[ "$patch_line" =~ \+([0-9]+) ]]; then
        new_line="${BASH_REMATCH[1]}"
      fi
      continue
    fi
    if [[ "$patch_line" == "+"* && "$patch_line" != "+++"* ]]; then
      local content="${patch_line:1}"
      local index
      if [[ "$content" == *"sanitization:allow"* ]]; then
        ((new_line++))
        continue
      fi
      for index in "${!PATTERN_REGEXES[@]}"; do
        if [[ "$content" =~ ${PATTERN_REGEXES[$index]} ]]; then
          record_content_finding "$current_file" "$new_line" "${PATTERN_NAMES[$index]}"
        fi
      done
      ((new_line++))
    fi
  done < <(git diff --no-color --unified=0 --diff-filter=ACMRT "$range" --)
}

for range in "${ranges[@]}"; do
  scan_range_for_content_findings "$range"
done

print_findings() {
  local heading="$1"
  shift
  local finding=""

  printf '%s\n' "$heading"
  for finding in "$@"; do
    IFS='|' read -r path line reason <<<"$finding"
    if [[ -n "$line" ]]; then
      printf '  - %s:%s (%s)\n' "$path" "$line" "$reason"
    else
      printf '  - %s (%s)\n' "$path" "$reason"
    fi
  done
}

if [[ ${#path_findings[@]} -gt 0 || ${#content_findings[@]} -gt 0 ]]; then
  error "Push blocked by sanitization checks."
  if [[ ${#path_findings[@]} -gt 0 ]]; then
    print_findings "Sensitive file findings:" "${path_findings[@]}"
  fi
  if [[ ${#content_findings[@]} -gt 0 ]]; then
    print_findings "Potential secret findings:" "${content_findings[@]}"
  fi
  printf 'Fix findings before push. For intentional examples only, add `sanitization:allow` to the exact line.\n' >&2
  exit 1
fi

npm_has_script() {
  local script_name="$1"
  node -e "const scripts=require('./package.json').scripts||{}; process.exit(Object.prototype.hasOwnProperty.call(scripts, process.argv[1]) ? 0 : 1);" "$script_name"
}

npm_script_value() {
  local script_name="$1"
  node -e "const scripts=require('./package.json').scripts||{}; const value=scripts[process.argv[1]]; if (typeof value === 'string') { process.stdout.write(value); } else { process.exit(1); }" "$script_name"
}

next_major_version() {
  node -e "const pkg=require('./package.json'); const version=(pkg.dependencies&&pkg.dependencies.next)||(pkg.devDependencies&&pkg.devDependencies.next)||''; const match=version.match(/[0-9]+/); if (match) process.stdout.write(match[0]);"
}

run_required_npm_script() {
  local script_name="$1"
  local label="$2"
  if ! npm_has_script "$script_name"; then
    fail "Required npm script '$script_name' is missing for the pre-push quality gate."
  fi
  log "Running ${label}: npm run ${script_name}"
  npm run "$script_name"
}

run_optional_npm_script() {
  local script_name="$1"
  local label="$2"
  if npm_has_script "$script_name"; then
    log "Running ${label}: npm run ${script_name}"
    npm run "$script_name"
  else
    log "Skipping ${label}: npm script '${script_name}' is not defined."
  fi
}

run_lint_gate_if_supported() {
  if ! npm_has_script "lint"; then
    log "Skipping lint checks: npm script 'lint' is not defined."
    return
  fi

  local lint_command=""
  local next_major=""
  lint_command="$(npm_script_value "lint" || true)"
  next_major="$(next_major_version || true)"

  if [[ "$lint_command" == *"next lint"* ]] && [[ -n "$next_major" ]] && (( next_major >= 16 )); then
    log "Skipping lint checks: 'next lint' is not supported in Next.js >= 16. Update lint script to eslint to re-enable."
    return
  fi

  run_required_npm_script "lint" "lint checks"
}

run_lint_gate_if_supported
run_required_npm_script "typecheck" "type checks"
run_optional_npm_script "test" "test suite"

log "All sanitization and quality gates passed."
