#!/usr/bin/env bash
set -euo pipefail

file="CLAUDE.md"
checksum_file=".claude-md.sha256"

if [[ ! -f "${file}" ]]; then
  echo "ERROR: ${file} is required."
  exit 1
fi

if [[ ! -f "${checksum_file}" ]]; then
  echo "ERROR: ${checksum_file} is required."
  exit 1
fi

expected="$(tr -d '[:space:]' < "${checksum_file}")"
actual="$(shasum -a 256 "${file}" | awk '{print $1}')"

if [[ "${actual}" != "${expected}" ]]; then
  echo "ERROR: ${file} content differs from locked JAGS original guidance."
  echo "If you need to update from upstream, replace ${file} verbatim and update ${checksum_file} intentionally."
  exit 1
fi

echo "OK: ${file} matches locked original guidance"

