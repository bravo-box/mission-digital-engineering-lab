#!/usr/bin/env bash
set -euo pipefail

sudo install -d -o vscode -g vscode \
  "${AZURE_CONFIG_DIR}" \
  "${TF_PLUGIN_CACHE_DIR}"
sudo chown -R vscode:vscode "${AZURE_CONFIG_DIR}" "${TF_PLUGIN_CACHE_DIR}"

printf 'Infrastructure toolchain:\n'
terraform version | head -n 1
packer version
az version --query '"azure-cli"' --output tsv
kubectl version --client=true --output=yaml | awk '/gitVersion:/ { print "kubectl " $2; exit }'
helm version --short
jq --version
shellcheck --version | awk '/^version:/ { print "ShellCheck " $2 }'
