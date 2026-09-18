#!/usr/bin/env bash
#
# deploy-terraform.sh - Plan, deploy or destroy the lab Terraform environment
# in /infra using the Azure CLI authenticated user.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

INFRA_DIR="${INFRA_DIR:-${REPO_ROOT}/infra}"
VAR_FILE="${VAR_FILE:-${INFRA_DIR}/terraform.tfvars}"
PLAN_FILE="${PLAN_FILE:-${INFRA_DIR}/tfplan}"
ACTION=""
AUTO_APPROVE="false"

usage() {
  cat <<USAGE
Usage: $(basename "$0") <plan|deploy|destroy> [options]

Actions:
  plan      Initialise the configuration and write a plan to ${PLAN_FILE}
  deploy    Apply the configuration
  destroy   Destroy every resource managed by the configuration

Options:
  -f, --var-file PATH      Terraform variables file (default: ${VAR_FILE})
  -s, --subscription ID    Subscription to deploy into (default: current CLI subscription)
  -c, --cloud NAME         Azure cloud name (default: ${AZURE_CLOUD})
  -y, --auto-approve       Do not prompt before applying or destroying
  -h, --help               Show this help
USAGE
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

case "$1" in
  plan|deploy|destroy) ACTION="$1"; shift ;;
  -h|--help) usage; exit 0 ;;
  *) err "Unknown action: $1"; usage; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--var-file) VAR_FILE="$2"; shift 2 ;;
    -s|--subscription) SUBSCRIPTION_ID="$2"; shift 2 ;;
    -c|--cloud) AZURE_CLOUD="$2"; shift 2 ;;
    -y|--auto-approve) AUTO_APPROVE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

require_command az terraform
ensure_azure_login

TF_ARGS=()
if [[ -f "${VAR_FILE}" ]]; then
  TF_ARGS+=("-var-file=${VAR_FILE}")
  log "Using variables file ${VAR_FILE}"
else
  log "Variables file ${VAR_FILE} not found, relying on defaults and TF_VAR_* environment variables"
fi

log "Initialising Terraform in ${INFRA_DIR}"
terraform -chdir="${INFRA_DIR}" init -input=false

log "Validating configuration"
terraform -chdir="${INFRA_DIR}" validate

case "${ACTION}" in
  plan)
    terraform -chdir="${INFRA_DIR}" plan -input=false "${TF_ARGS[@]+"${TF_ARGS[@]}"}" -out="${PLAN_FILE}"
    log "Plan written to ${PLAN_FILE}"
    ;;
  deploy)
    APPLY_ARGS=(-input=false)
    [[ "${AUTO_APPROVE}" == "true" ]] && APPLY_ARGS+=(-auto-approve)
    terraform -chdir="${INFRA_DIR}" apply "${APPLY_ARGS[@]}" "${TF_ARGS[@]+"${TF_ARGS[@]}"}"
    log "Deployment complete"
    ;;
  destroy)
    DESTROY_ARGS=(-input=false)
    [[ "${AUTO_APPROVE}" == "true" ]] && DESTROY_ARGS+=(-auto-approve)
    terraform -chdir="${INFRA_DIR}" destroy "${DESTROY_ARGS[@]}" "${TF_ARGS[@]+"${TF_ARGS[@]}"}"
    log "Destroy complete"
    ;;
esac
