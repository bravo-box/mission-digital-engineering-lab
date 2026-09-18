#!/usr/bin/env bash
#
# creating-lz.sh - Create the landing zone virtual network that the lab
# Terraform configuration attaches to.
#
# Authentication uses the Azure CLI user (az login) against Azure Government
# by default.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-delab-network}"
LOCATION="${LOCATION:-usgovvirginia}"
VNET_NAME="${VNET_NAME:-vnet-delab}"
VNET_ADDRESS_SPACE="${VNET_ADDRESS_SPACE:-10.100.0.0/16}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Creates the resource group and virtual network used as the landing zone for the
digital engineering lab.

Options:
  -g, --resource-group NAME   Resource group for the virtual network (default: ${RESOURCE_GROUP})
  -l, --location REGION       Azure region (default: ${LOCATION})
  -n, --name NAME             Virtual network name (default: ${VNET_NAME})
  -a, --address-space CIDR    Virtual network address space (default: ${VNET_ADDRESS_SPACE})
  -s, --subscription ID       Subscription to deploy into (default: current CLI subscription)
  -c, --cloud NAME            Azure cloud name (default: ${AZURE_CLOUD})
  -h, --help                  Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    -l|--location) LOCATION="$2"; shift 2 ;;
    -n|--name) VNET_NAME="$2"; shift 2 ;;
    -a|--address-space) VNET_ADDRESS_SPACE="$2"; shift 2 ;;
    -s|--subscription) SUBSCRIPTION_ID="$2"; shift 2 ;;
    -c|--cloud) AZURE_CLOUD="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

require_command az
ensure_azure_login

log "Creating resource group ${RESOURCE_GROUP} in ${LOCATION}"
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none

log "Creating virtual network ${VNET_NAME} (${VNET_ADDRESS_SPACE})"
az network vnet create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VNET_NAME}" \
  --location "${LOCATION}" \
  --address-prefixes "${VNET_ADDRESS_SPACE}" \
  --output none

log "Landing zone ready. Use these values in infra/terraform.tfvars:"
cat <<EOF

virtual_network_name                = "${VNET_NAME}"
virtual_network_resource_group_name = "${RESOURCE_GROUP}"
location                            = "${LOCATION}"

EOF
