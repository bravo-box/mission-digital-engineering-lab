#!/usr/bin/env bash
#
# create-matlab-vm.sh - Create a MATLAB development VM from a Packer image.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

VM_NAME=""
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-delab-lab}"
LOCATION="${LOCATION:-usgovvirginia}"
VM_SIZE="${VM_SIZE:-Standard_D8s_v5}"
ADMIN_USERNAME="${ADMIN_USERNAME:-azureuser}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
SSH_KEY_PATH="${SSH_KEY_PATH:-}"
SUBNET_ID="${SUBNET_ID:-}"
IMAGE_RESOURCE_GROUP="${IMAGE_RESOURCE_GROUP:-rg-delab-packer}"
IMAGE_NAME="${IMAGE_NAME:-}"
IMAGE_ID="${IMAGE_ID:-}"
OS_TYPE="${OS_TYPE:-linux}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") --name NAME [options]

Creates a private Linux or Windows VM from a managed image produced by the
corresponding Packer template.

Options:
  -n, --name NAME               VM name (required)
      --os TYPE                 Image operating system: linux or windows
                                 (default: ${OS_TYPE})
  -g, --resource-group NAME     VM resource group (default: ${RESOURCE_GROUP})
  -l, --location REGION         VM region (default: ${LOCATION})
      --size SKU                VM size (default: ${VM_SIZE})
      --admin-username NAME     Administrator username (default: ${ADMIN_USERNAME})
      --ssh-key PATH            Linux SSH public key (default: Azure CLI generated key)
      --subnet-id ID            Subnet resource ID (default: Terraform matlab-vms output)
      --image-resource-group RG Managed image resource group (default: ${IMAGE_RESOURCE_GROUP})
      --image-name NAME         Managed image name (default: matlab-dev-linux or
                                 matlab-dev-windows2022, based on --os)
      --image-id ID             Full managed-image resource ID; overrides image
                                 resource group and name
  -s, --subscription ID         Subscription to deploy into (default: current CLI subscription)
  -c, --cloud NAME              Azure cloud name (default: ${AZURE_CLOUD})
  -h, --help                    Show this help

Windows authentication uses ADMIN_PASSWORD from the environment or prompts
securely when run from a terminal. The VM has no public IP. Configure MATLAB
to use the network license manager after deployment.
USAGE
}

require_value() {
  if [[ $# -lt 2 || -z "$2" ]]; then
    err "Option '$1' requires a value."
    usage
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name) require_value "$@"; VM_NAME="$2"; shift 2 ;;
    --os) require_value "$@"; OS_TYPE="${2,,}"; shift 2 ;;
    -g|--resource-group) require_value "$@"; RESOURCE_GROUP="$2"; shift 2 ;;
    -l|--location) require_value "$@"; LOCATION="$2"; shift 2 ;;
    --size) require_value "$@"; VM_SIZE="$2"; shift 2 ;;
    --admin-username) require_value "$@"; ADMIN_USERNAME="$2"; shift 2 ;;
    --ssh-key) require_value "$@"; SSH_KEY_PATH="$2"; shift 2 ;;
    --subnet-id) require_value "$@"; SUBNET_ID="$2"; shift 2 ;;
    --image-resource-group) require_value "$@"; IMAGE_RESOURCE_GROUP="$2"; shift 2 ;;
    --image-name) require_value "$@"; IMAGE_NAME="$2"; shift 2 ;;
    --image-id) require_value "$@"; IMAGE_ID="$2"; shift 2 ;;
    -s|--subscription) require_value "$@"; SUBSCRIPTION_ID="$2"; shift 2 ;;
    -c|--cloud) require_value "$@"; AZURE_CLOUD="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "${VM_NAME}" ]]; then
  err "--name is required."
  usage
  exit 1
fi

case "${OS_TYPE}" in
  linux)
    IMAGE_NAME="${IMAGE_NAME:-matlab-dev-linux}"
    if [[ -n "${SSH_KEY_PATH}" && ! -f "${SSH_KEY_PATH}" ]]; then
      err "SSH public key '${SSH_KEY_PATH}' does not exist."
      exit 1
    fi
    ;;
  windows)
    IMAGE_NAME="${IMAGE_NAME:-matlab-dev-windows2022}"
    if [[ -n "${SSH_KEY_PATH}" ]]; then
      err "--ssh-key is only valid with --os linux."
      exit 1
    fi
    ;;
  *)
    err "Unsupported operating system '${OS_TYPE}'. Use 'linux' or 'windows'."
    exit 1
    ;;
esac

require_command az
ensure_azure_login

if ! az group show --name "${RESOURCE_GROUP}" --output none 2>/dev/null; then
  err "VM resource group '${RESOURCE_GROUP}' does not exist."
  exit 1
fi

if [[ -z "${SUBNET_ID}" ]]; then
  require_command terraform jq
  if ! SUBNET_ID="$(terraform -chdir="${REPO_ROOT}/infra" output -json subnet_ids 2>/dev/null | jq -er '."matlab-vms"')"; then
    err "Could not read the matlab-vms subnet from Terraform. Pass --subnet-id explicitly."
    exit 1
  fi
  log "Using matlab-vms subnet from the Terraform outputs"
fi

if [[ -z "${IMAGE_ID}" ]]; then
  IMAGE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${IMAGE_RESOURCE_GROUP}/providers/Microsoft.Compute/images/${IMAGE_NAME}"
fi

log "Validating managed image ${IMAGE_ID}"
if ! IMAGE_OS_TYPE="$(az image show --ids "${IMAGE_ID}" --query storageProfile.osDisk.osType --output tsv)"; then
  err "Could not find or access managed image '${IMAGE_ID}'."
  exit 1
fi

if [[ "${IMAGE_OS_TYPE,,}" != "${OS_TYPE}" ]]; then
  err "Managed image '${IMAGE_ID}' contains ${IMAGE_OS_TYPE}, not the requested ${OS_TYPE} OS."
  exit 1
fi

AUTH_ARGS=()
case "${OS_TYPE}" in
  linux)
    AUTH_ARGS=(--authentication-type ssh --generate-ssh-keys)
    if [[ -n "${SSH_KEY_PATH}" ]]; then
      AUTH_ARGS=(--authentication-type ssh --ssh-key-values "${SSH_KEY_PATH}")
    fi
    ;;
  windows)
    if [[ -z "${ADMIN_PASSWORD}" ]]; then
      if [[ ! -t 0 ]]; then
        err "Set ADMIN_PASSWORD when creating a Windows VM non-interactively."
        exit 1
      fi
      read -r -s -p "Windows administrator password: " ADMIN_PASSWORD
      printf '\n'
    fi
    AUTH_ARGS=(--authentication-type password --admin-password "${ADMIN_PASSWORD}")
    ;;
esac

log "Creating private ${OS_TYPE} VM ${VM_NAME} in ${RESOURCE_GROUP}"
az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --location "${LOCATION}" \
  --image "${IMAGE_ID}" \
  --size "${VM_SIZE}" \
  --admin-username "${ADMIN_USERNAME}" \
  "${AUTH_ARGS[@]}" \
  --subnet "${SUBNET_ID}" \
  --public-ip-address "" \
  --tags workload=digital-engineering-lab role="matlab-dev-${OS_TYPE}-vm" \
  --output table

log "VM ${VM_NAME} is ready. Configure MLM_LICENSE_FILE before starting MATLAB."
