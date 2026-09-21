#!/usr/bin/env bash
#
# install-docker-ubuntu.sh - Install Docker Engine for devcontainer workloads.
#
# Supported operating system: Ubuntu 24.04 LTS.
set -euo pipefail

TARGET_USER="${SUDO_USER:-${USER:-}}"

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

err() {
  printf '[%s] ERROR: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Installs Docker Engine, Buildx and Docker Compose from Docker's official apt
repository on Ubuntu 24.04 LTS. The target user is added to the docker group so
devcontainer tooling can access the Docker socket without sudo.

Options:
  -u, --user USER   User to add to the docker group
                    (default: the user that invoked sudo, or the current user)
  -h, --help        Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user)
      if [[ $# -lt 2 ]]; then
        err "Option '$1' requires a user name."
        usage
        exit 1
      fi
      TARGET_USER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -r /etc/os-release ]]; then
  err "Cannot determine the operating system because /etc/os-release is unavailable."
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
  err "This script supports Ubuntu 24.04 LTS only (detected ${PRETTY_NAME:-unknown})."
  exit 1
fi

if [[ -z "${TARGET_USER}" ]] || ! id "${TARGET_USER}" >/dev/null 2>&1; then
  err "Target user '${TARGET_USER:-<empty>}' does not exist. Specify one with --user."
  exit 1
fi

if [[ "${TARGET_USER}" == "root" ]]; then
  err "Specify the non-root user that will run devcontainers with --user."
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=()
elif command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  err "Run this script as root or install sudo."
  exit 1
fi

log "Installing apt prerequisites"
"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y ca-certificates curl

log "Removing packages that conflict with Docker Engine"
"${SUDO[@]}" apt-get remove -y \
  docker.io \
  docker-compose \
  docker-compose-v2 \
  docker-doc \
  podman-docker \
  containerd \
  runc

log "Configuring Docker's official apt repository"
"${SUDO[@]}" install -m 0755 -d /etc/apt/keyrings
"${SUDO[@]}" curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
"${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.asc

ARCHITECTURE="$(dpkg --print-architecture)"
"${SUDO[@]}" tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

log "Installing Docker Engine, Buildx and Docker Compose"
"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

log "Enabling the Docker service"
"${SUDO[@]}" systemctl enable --now docker

log "Granting ${TARGET_USER} access to the Docker socket"
"${SUDO[@]}" groupadd --force docker
"${SUDO[@]}" usermod -aG docker "${TARGET_USER}"

if ! "${SUDO[@]}" docker info >/dev/null; then
  err "Docker was installed, but the daemon did not respond."
  exit 1
fi

log "Docker $(docker --version | sed 's/^Docker version //') is ready."
log "Log out and back in before running Docker or devcontainers as ${TARGET_USER}."
