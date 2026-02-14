#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/state-path.sh"

allowed_keys=(OPENAI_API_KEY PPLX_API_KEY GEMINI_API_KEY)

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/research-secrets.sh init
  ./scripts/research-secrets.sh path
  ./scripts/research-secrets.sh set <OPENAI_API_KEY|PPLX_API_KEY|GEMINI_API_KEY> [value]
  ./scripts/research-secrets.sh unset <OPENAI_API_KEY|PPLX_API_KEY|GEMINI_API_KEY>
  ./scripts/research-secrets.sh status
  ./scripts/research-secrets.sh validate [codex-only|multi-provider]
USAGE
}

is_allowed_key() {
  local key="${1:-}"
  for allowed in "${allowed_keys[@]}"; do
    if [[ "${allowed}" == "${key}" ]]; then
      return 0
    fi
  done
  return 1
}

secrets_path_for_write() {
  if [[ -n "${RESEARCH_SECRETS_FILE:-}" ]]; then
    echo "${RESEARCH_SECRETS_FILE}"
    return 0
  fi
  echo "$(state_dir_writable)/research-secrets.env"
}

secrets_path_for_read() {
  if [[ -n "${RESEARCH_SECRETS_FILE:-}" ]]; then
    echo "${RESEARCH_SECRETS_FILE}"
    return 0
  fi

  local primary="${primary_state_dir}/research-secrets.env"
  local fallback="${fallback_state_dir}/research-secrets.env"
  if [[ -f "${primary}" ]]; then
    echo "${primary}"
    return 0
  fi
  if [[ -f "${fallback}" ]]; then
    echo "${fallback}"
    return 0
  fi
  echo "${primary}"
}

escape_single_quotes() {
  printf '%s' "$1" | sed "s/'/'\"'\"'/g"
}

load_from_file() {
  local file="${1}"
  if [[ -f "${file}" ]]; then
    # DECISION: Source only controlled local env file created by this script to keep key parsing simple.
    # shellcheck disable=SC1090
    source "${file}"
  fi
}

mask_secret() {
  local value="${1:-}"
  local n="${#value}"
  if (( n == 0 )); then
    printf "missing"
    return 0
  fi
  if (( n <= 8 )); then
    printf "present(%s chars)" "${n}"
    return 0
  fi
  printf "%s...%s (%s chars)" "${value:0:4}" "${value: -4}" "${n}"
}

get_research_mode() {
  local mode_file mode
  mode_file="${RESEARCH_MODE_FILE:-$(resolve_state_file_for_read "research-mode")}" 
  if [[ ! -f "${mode_file}" ]]; then
    echo "codex-only"
    return 0
  fi
  mode="$(cut -d'|' -f1 "${mode_file}" || true)"
  if [[ "${mode}" != "codex-only" && "${mode}" != "multi-provider" ]]; then
    echo "codex-only"
    return 0
  fi
  echo "${mode}"
}

cmd="${1:-}"
case "${cmd}" in
  init)
    file="$(secrets_path_for_write)"
    mkdir -p "$(dirname "${file}")"
    if [[ ! -f "${file}" ]]; then
      cat > "${file}" <<'SECRETS'
# Research provider secrets (ignored by git)
# Set with: ./scripts/research-secrets.sh set <KEY>
# Allowed keys: OPENAI_API_KEY, PPLX_API_KEY, GEMINI_API_KEY
SECRETS
      chmod 600 "${file}"
      echo "Initialized ${file}"
    else
      chmod 600 "${file}" || true
      echo "Secrets file already exists: ${file}"
    fi
    ;;

  path)
    echo "$(secrets_path_for_read)"
    ;;

  set)
    key="${2:-}"
    if ! is_allowed_key "${key}"; then
      echo "ERROR: invalid key '${key:-}'"
      usage
      exit 1
    fi

    value="${3:-}"
    if [[ -z "${value}" ]]; then
      read -r -s -p "Enter value for ${key}: " value
      echo
    fi

    if [[ -z "${value}" ]]; then
      echo "ERROR: value cannot be empty"
      exit 1
    fi

    file="$(secrets_path_for_write)"
    mkdir -p "$(dirname "${file}")"
    touch "${file}"
    chmod 600 "${file}" || true

    tmp="$(mktemp)"
    if [[ -f "${file}" ]]; then
      rg -v "^${key}=" "${file}" > "${tmp}" || true
    fi
    escaped="$(escape_single_quotes "${value}")"
    printf "%s='%s'\n" "${key}" "${escaped}" >> "${tmp}"
    mv "${tmp}" "${file}"
    chmod 600 "${file}" || true

    echo "Stored ${key} in ${file}"
    ;;

  unset)
    key="${2:-}"
    if ! is_allowed_key "${key}"; then
      echo "ERROR: invalid key '${key:-}'"
      usage
      exit 1
    fi
    file="$(secrets_path_for_write)"
    if [[ ! -f "${file}" ]]; then
      echo "No secrets file found at ${file}"
      exit 0
    fi
    tmp="$(mktemp)"
    rg -v "^${key}=" "${file}" > "${tmp}" || true
    mv "${tmp}" "${file}"
    chmod 600 "${file}" || true
    echo "Removed ${key} from ${file}"
    ;;

  status)
    file="$(secrets_path_for_read)"
    load_from_file "${file}"
    echo "Secrets file: ${file}"
    for key in "${allowed_keys[@]}"; do
      value="${!key:-}"
      printf "  - %s: %s\n" "${key}" "$(mask_secret "${value}")"
    done
    ;;

  validate)
    mode="${2:-$(get_research_mode)}"
    file="$(secrets_path_for_read)"
    load_from_file "${file}"

    case "${mode}" in
      codex-only)
        echo "OK: codex-only mode does not require provider tokens"
        exit 0
        ;;
      multi-provider)
        ;;
      *)
        echo "ERROR: unknown mode '${mode}'"
        exit 1
        ;;
    esac

    missing=()
    for key in "${allowed_keys[@]}"; do
      if [[ -z "${!key:-}" ]]; then
        missing+=("${key}")
      fi
    done

    if [[ "${#missing[@]}" -gt 0 ]]; then
      dir="$(state_dir_writable)"
      {
        echo "research-secrets|missing required keys for multi-provider|$(date +%s)"
        printf 'missing|%s\n' "${missing[@]}"
      } > "${dir}/agent-findings"
      echo "ERROR: missing required provider secrets for multi-provider mode:"
      printf "  - %s\n" "${missing[@]}"
      echo "Run: ./scripts/research-secrets.sh set <KEY>"
      exit 1
    fi

    echo "OK: research secrets validated for multi-provider mode"
    ;;

  help|-h|--help|"")
    usage
    ;;

  *)
    echo "ERROR: unknown command '${cmd}'"
    usage
    exit 1
    ;;
esac
