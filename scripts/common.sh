#!/usr/bin/env bash
#
# common.sh - Shared helpers for the repository scripts.
#
# This file is meant to be sourced, not executed.

AZURE_CLOUD="${AZURE_CLOUD:-AzureUSGovernment}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

err() {
  printf '[%s] ERROR: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}

require_command() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      err "Required command '${cmd}' was not found on PATH."
      exit 1
    fi
  done
}

# Make sure the Azure CLI points at the requested cloud and is logged in.
ensure_azure_login() {
  local current_cloud
  current_cloud="$(az cloud show --query name --output tsv 2>/dev/null || true)"

  if [[ "${current_cloud}" != "${AZURE_CLOUD}" ]]; then
    log "Switching Azure CLI to cloud ${AZURE_CLOUD}"
    az cloud set --name "${AZURE_CLOUD}" >/dev/null
  fi

  if ! az account show --output none 2>/dev/null; then
    err "Not logged in to ${AZURE_CLOUD}. Run 'az cloud set --name ${AZURE_CLOUD} && az login' first."
    exit 1
  fi

  if [[ -n "${SUBSCRIPTION_ID}" ]]; then
    log "Selecting subscription ${SUBSCRIPTION_ID}"
    az account set --subscription "${SUBSCRIPTION_ID}"
  fi

  SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
  export ARM_SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"

  case "${AZURE_CLOUD}" in
    AzureUSGovernment) export ARM_ENVIRONMENT="usgovernment" ;;
    AzureCloud) export ARM_ENVIRONMENT="public" ;;
    AzureChinaCloud) export ARM_ENVIRONMENT="china" ;;
    *) err "Unsupported cloud '${AZURE_CLOUD}'."; exit 1 ;;
  esac

  export ARM_USE_CLI="true"
  log "Using cloud ${AZURE_CLOUD}, subscription ${SUBSCRIPTION_ID}"
}
