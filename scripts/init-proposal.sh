#!/usr/bin/env bash
set -euo pipefail

proposal_file="${1:-PROPOSAL.md}"
template="docs/PROPOSAL-TEMPLATE.md"

if [[ -f "${proposal_file}" ]]; then
  echo "Proposal file already exists: ${proposal_file}"
  exit 0
fi

if [[ ! -f "${template}" ]]; then
  echo "ERROR: missing template at ${template}"
  exit 1
fi

cp "${template}" "${proposal_file}"
echo "Initialized ${proposal_file} from ${template}"

