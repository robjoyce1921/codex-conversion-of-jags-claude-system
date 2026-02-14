#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository. Run: git init"
  exit 1
fi

chmod +x scripts/*.sh
chmod +x .githooks/*

git config core.hooksPath .githooks

echo "Installed hooks at .githooks via core.hooksPath"
echo "Optional safer git wrapper: ./scripts/git-safe.sh <git args>"

