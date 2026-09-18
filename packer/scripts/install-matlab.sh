#!/usr/bin/env bash
#
# install-matlab.sh - Provision a MATLAB development VM image.
#
# Installs the MATLAB dependencies and the requested MathWorks products with
# the MathWorks package manager (mpm). Licensing is handled at runtime through
# a network license manager, so no license file is baked into the image.
set -euo pipefail

MATLAB_RELEASE="${MATLAB_RELEASE:-R2024b}"
MATLAB_PRODUCTS="${MATLAB_PRODUCTS:-MATLAB}"
MATLAB_INSTALL_DIR="${MATLAB_INSTALL_DIR:-/opt/matlab/${MATLAB_RELEASE}}"
MPM_URL="${MPM_URL:-https://www.mathworks.com/mpm/glnxa64/mpm}"

export DEBIAN_FRONTEND=noninteractive

echo "Installing base packages"
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  unzip \
  openssh-client \
  python3 \
  python3-pip \
  libgl1 \
  libglu1-mesa \
  libxt6 \
  libxrender1 \
  libxtst6 \
  libx11-6 \
  libxext6 \
  xvfb

echo "Downloading MathWorks package manager from ${MPM_URL}"
curl -fsSL "${MPM_URL}" -o /tmp/mpm
chmod +x /tmp/mpm

echo "Installing ${MATLAB_RELEASE}: ${MATLAB_PRODUCTS}"
# shellcheck disable=SC2086
/tmp/mpm install \
  --release="${MATLAB_RELEASE}" \
  --destination="${MATLAB_INSTALL_DIR}" \
  --products ${MATLAB_PRODUCTS}

rm -f /tmp/mpm

ln -sf "${MATLAB_INSTALL_DIR}/bin/matlab" /usr/local/bin/matlab

echo "Cleaning up"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "MATLAB ${MATLAB_RELEASE} installed in ${MATLAB_INSTALL_DIR}"
