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
SSH_KEY_PATH="${SSH_KEY_PATH:-}"
SUBNET_ID="${SUBNET_ID:-}"
IMAGE_RESOURCE_GROUP="${IMAGE_RESOURCE_GROUP:-rg-delab-packer}"
IMAGE_NAME="${IMAGE_NAME:-matlab-dev-ubuntu2204}"
GALLERY_NAME="${GALLERY_NAME:-}"
GALLERY_RESOURCE_GROUP="${GALLERY_RESOURCE_GROUP:-}"
IMAGE_VERSION="${IMAGE_VERSION:-1.0.0}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") --name NAME [options]

Creates a private Linux VM from the managed image or Azure Compute Gallery
image produced by packer/matlab-dev-vm.pkr.hcl.

Options:
  -n, --name NAME               VM name (required)
  -g, --resource-group NAME     VM resource group (default: ${RESOURCE_GROUP})
  -l, --location REGION         VM region (default: ${LOCATION})
      --size SKU                VM size (default: ${VM_SIZE})
      --admin-username NAME     Administrator username (default: ${ADMIN_USERNAME})
      --ssh-key PATH            Existing SSH public key (default: Azure CLI generated key)
      --subnet-id ID            Subnet resource ID (default: Terraform matlab-vms output)
      --image-resource-group RG Managed image resource group (default: ${IMAGE_RESOURCE_GROUP})
      --image-name NAME         Managed or gallery image definition (default: ${IMAGE_NAME})
      --gallery NAME            Use an Azure Compute Gallery image
      --gallery-resource-group RG
                                 Gallery resource group (default: image resource group)
      --image-version VERSION   Gallery image version (default: ${IMAGE_VERSION})
  -s, --subscription ID         Subscription to deploy into (default: current CLI subscription)
  -c, --cloud NAME              Azure cloud name (default: ${AZURE_CLOUD})
  -h, --help                    Show this help

The VM has no public IP. Set MLM_LICENSE_FILE after deployment to point MATLAB
at the network license manager.
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
    -g|--resource-group) require_value "$@"; RESOURCE_GROUP="$2"; shift 2 ;;
    -l|--location) require_value "$@"; LOCATION="$2"; shift 2 ;;
    --size) require_value "$@"; VM_SIZE="$2"; shift 2 ;;
    --admin-username) require_value "$@"; ADMIN_USERNAME="$2"; shift 2 ;;
    --ssh-key) require_value "$@"; SSH_KEY_PATH="$2"; shift 2 ;;
    --subnet-id) require_value "$@"; SUBNET_ID="$2"; shift 2 ;;
    --image-resource-group) require_value "$@"; IMAGE_RESOURCE_GROUP="$2"; shift 2 ;;
    --image-name) require_value "$@"; IMAGE_NAME="$2"; shift 2 ;;
    --gallery) require_value "$@"; GALLERY_NAME="$2"; shift 2 ;;
    --gallery-resource-group) require_value "$@"; GALLERY_RESOURCE_GROUP="$2"; shift 2 ;;
    --image-version) require_value "$@"; IMAGE_VERSION="$2"; shift 2 ;;
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

if [[ -n "${SSH_KEY_PATH}" && ! -f "${SSH_KEY_PATH}" ]]; then
  err "SSH public key '${SSH_KEY_PATH}' does not exist."
  exit 1
fi

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

if [[ -n "${GALLERY_NAME}" ]]; then
  GALLERY_RESOURCE_GROUP="${GALLERY_RESOURCE_GROUP:-${IMAGE_RESOURCE_GROUP}}"
  log "Resolving gallery image ${GALLERY_NAME}/${IMAGE_NAME}/${IMAGE_VERSION}"
  IMAGE_ID="$(az sig image-version show \
    --resource-group "${GALLERY_RESOURCE_GROUP}" \
    --gallery-name "${GALLERY_NAME}" \
    --gallery-image-definition "${IMAGE_NAME}" \
    --gallery-image-version "${IMAGE_VERSION}" \
    --query id \
    --output tsv)"
else
  log "Resolving managed image ${IMAGE_RESOURCE_GROUP}/${IMAGE_NAME}"
  IMAGE_ID="$(az image show \
    --resource-group "${IMAGE_RESOURCE_GROUP}" \
    --name "${IMAGE_NAME}" \
    --query id \
    --output tsv)"
fi

if [[ -z "${IMAGE_ID}" ]]; then
  err "Azure returned an empty image ID."
  exit 1
fi

SSH_ARGS=(--generate-ssh-keys)
if [[ -n "${SSH_KEY_PATH}" ]]; then
  SSH_ARGS=(--ssh-key-values "${SSH_KEY_PATH}")
fi

log "Creating private VM ${VM_NAME} in ${RESOURCE_GROUP}"
az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --location "${LOCATION}" \
  --image "${IMAGE_ID}" \
  --size "${VM_SIZE}" \
  --admin-username "${ADMIN_USERNAME}" \
  --authentication-type ssh \
  "${SSH_ARGS[@]}" \
  --subnet "${SUBNET_ID}" \
  --public-ip-address "" \
  --tags workload=digital-engineering-lab role=matlab-dev-vm \
  --output table

log "VM ${VM_NAME} is ready. Configure MLM_LICENSE_FILE before starting MATLAB."
