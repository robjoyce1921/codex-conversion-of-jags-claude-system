#!/usr/bin/env bash
set -euo pipefail

if [[ "${SKIP_TESTS:-0}" == "1" ]]; then
  echo "SKIP_TESTS=1 set; skipping tests"
  exit 0
fi

if [[ -x "./scripts/test.sh" ]]; then
  echo "Running ./scripts/test.sh"
  ./scripts/test.sh
  exit 0
fi

if [[ -f "Makefile" ]] && rg -q '^test:' Makefile; then
  echo "Running make test"
  make test
  exit 0
fi

if [[ -f "package.json" ]] && command -v npm >/dev/null 2>&1; then
  if rg -q '"test"[[:space:]]*:' package.json; then
    echo "Running npm test"
    npm test --silent
    exit 0
  fi
fi

if [[ -d "tests" ]] && command -v pytest >/dev/null 2>&1; then
  echo "Running pytest -q"
  pytest -q
  exit 0
fi

if [[ -f "go.mod" ]] && command -v go >/dev/null 2>&1; then
  echo "Running go test ./..."
  go test ./...
  exit 0
fi

if [[ -f "Cargo.toml" ]] && command -v cargo >/dev/null 2>&1; then
  echo "Running cargo test --all-targets --quiet"
  cargo test --all-targets --quiet
  exit 0
fi

echo "No test command discovered; passing by policy"

