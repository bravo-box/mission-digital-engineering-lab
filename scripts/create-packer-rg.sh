#!/usr/bin/env bash
#
# create-packer-rg.sh - Create the resource group (and optional shared image
# gallery) that Packer builds land MATLAB VM images in.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

RESOURCE_GROUP="${PACKER_RESOURCE_GROUP:-rg-delab-packer}"
LOCATION="${LOCATION:-usgovvirginia}"
GALLERY_NAME="${GALLERY_NAME:-}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Creates the resource group used as the Packer build and image target.

Options:
  -g, --resource-group NAME   Packer resource group (default: ${RESOURCE_GROUP})
  -l, --location REGION       Azure region (default: ${LOCATION})
      --gallery NAME          Also create an Azure Compute Gallery with this name
  -s, --subscription ID       Subscription to deploy into (default: current CLI subscription)
  -c, --cloud NAME            Azure cloud name (default: ${AZURE_CLOUD})
  -h, --help                  Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    -l|--location) LOCATION="$2"; shift 2 ;;
    --gallery) GALLERY_NAME="$2"; shift 2 ;;
    -s|--subscription) SUBSCRIPTION_ID="$2"; shift 2 ;;
    -c|--cloud) AZURE_CLOUD="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

require_command az
ensure_azure_login

log "Creating Packer resource group ${RESOURCE_GROUP} in ${LOCATION}"
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags workload=digital-engineering-lab purpose=packer \
  --output none

if [[ -n "${GALLERY_NAME}" ]]; then
  log "Creating Azure Compute Gallery ${GALLERY_NAME}"
  az sig create \
    --resource-group "${RESOURCE_GROUP}" \
    --gallery-name "${GALLERY_NAME}" \
    --location "${LOCATION}" \
    --output none
fi

log "Packer target ready. Build with:"
cat <<EOF

  packer init packer/matlab-dev-linux-vm.pkr.hcl
  packer build -var "build_resource_group_name=${RESOURCE_GROUP}" \\
    packer/matlab-dev-linux-vm.pkr.hcl

EOF
