#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

write_status() {
  local status="${1}"
  local fail_count="${2:-0}"
  local dir
  dir="$(state_dir_writable)"
  echo "${status}|${fail_count}|$(date +%s)" > "${dir}/test-status"
}

run_and_record() {
  if "$@"; then
    write_status "pass" 0
    return 0
  fi
  write_status "fail" 1
  local dir
  dir="$(state_dir_writable)"
  echo "test-gate|tests failed during check-tests.sh|$(date +%s)" > "${dir}/agent-findings"
  return 1
}

if [[ "${SKIP_TESTS:-0}" == "1" ]]; then
  echo "SKIP_TESTS=1 set; skipping tests"
  write_status "pending" 0
  exit 0
fi

if [[ -x "./scripts/test.sh" ]]; then
  echo "Running ./scripts/test.sh"
  run_and_record ./scripts/test.sh
  exit 0
fi

if [[ -f "Makefile" ]] && rg -q '^test:' Makefile; then
  echo "Running make test"
  run_and_record make test
  exit 0
fi

if [[ -f "package.json" ]] && command -v npm >/dev/null 2>&1; then
  if rg -q '"test"[[:space:]]*:' package.json; then
    echo "Running npm test"
    run_and_record npm test --silent
    exit 0
  fi
fi

if [[ -d "tests" ]] && command -v pytest >/dev/null 2>&1; then
  echo "Running pytest -q"
  run_and_record pytest -q
  exit 0
fi

if [[ -f "go.mod" ]] && command -v go >/dev/null 2>&1; then
  echo "Running go test ./..."
  run_and_record go test ./...
  exit 0
fi

if [[ -f "Cargo.toml" ]] && command -v cargo >/dev/null 2>&1; then
  echo "Running cargo test --all-targets --quiet"
  run_and_record cargo test --all-targets --quiet
  exit 0
fi

echo "No test command discovered; passing by policy"
write_status "pending" 0
