#!/usr/bin/env bash
#
# Install the MathWorks Network License Manager without embedding a license.
set -euo pipefail

LICENSE_MANAGER_ARCHIVE_URL="${LICENSE_MANAGER_ARCHIVE_URL:?LICENSE_MANAGER_ARCHIVE_URL is required}"
LICENSE_MANAGER_ARCHIVE_SHA256="${LICENSE_MANAGER_ARCHIVE_SHA256:-}"
INSTALL_DIR="/opt/mathworks/network-license-manager"
LICENSE_DIR="/etc/mathworks"
LICENSE_FILE="${LICENSE_DIR}/license.dat"
LOG_DIR="/var/log/mathworks"
SERVICE_USER="matlab-license"
archive_path="/tmp/mathworks-network-license-manager.zip"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip

curl --fail --location --show-error \
  "${LICENSE_MANAGER_ARCHIVE_URL}" \
  --output "${archive_path}"

if [[ -n "${LICENSE_MANAGER_ARCHIVE_SHA256}" ]]; then
  echo "${LICENSE_MANAGER_ARCHIVE_SHA256}  ${archive_path}" | sha256sum --check -
fi

groupadd --system "${SERVICE_USER}"
useradd \
  --system \
  --gid "${SERVICE_USER}" \
  --home-dir "${INSTALL_DIR}" \
  --shell /usr/sbin/nologin \
  "${SERVICE_USER}"

install -d -m 0755 -o root -g root "${INSTALL_DIR}"
unzip -q "${archive_path}" -d "${INSTALL_DIR}"

lmgrd_path="$(find "${INSTALL_DIR}" -type f -path '*/etc/glnxa64/lmgrd' -print -quit)"
lmutil_path="$(find "${INSTALL_DIR}" -type f -path '*/etc/glnxa64/lmutil' -print -quit)"
mlm_path="$(find "${INSTALL_DIR}" -type f -path '*/etc/glnxa64/mlm' -print -quit)"

if [[ -z "${lmgrd_path}" || -z "${lmutil_path}" || -z "${mlm_path}" ]]; then
  echo "The archive does not contain the expected glnxa64 license manager binaries." >&2
  exit 1
fi

chmod 0755 "${lmgrd_path}" "${lmutil_path}" "${mlm_path}"
ln -s "${lmgrd_path}" /usr/local/sbin/lmgrd
ln -s "${lmutil_path}" /usr/local/bin/lmutil

# FlexNet expects the Linux Standard Base loader name.
if [[ ! -e /lib64/ld-lsb-x86-64.so.3 ]]; then
  ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
fi

install -d -m 0750 -o root -g "${SERVICE_USER}" "${LICENSE_DIR}"
install -d -m 0755 -o "${SERVICE_USER}" -g "${SERVICE_USER}" "${LOG_DIR}"

cat >/etc/systemd/system/matlab-license-manager.service <<EOF
[Unit]
Description=MathWorks Network License Manager
After=network-online.target
Wants=network-online.target
ConditionPathExists=${LICENSE_FILE}

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
ExecStart=/usr/local/sbin/lmgrd -z -2 -p -local -c ${LICENSE_FILE} -l ${LOG_DIR}/license-manager.log
ExecStop=/usr/local/bin/lmutil lmdown -q -force -c ${LICENSE_FILE}
Restart=on-failure
RestartSec=10
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable matlab-license-manager.service

rm -f "${archive_path}"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "MathWorks Network License Manager installed at ${INSTALL_DIR}"
echo "Install the host-specific license at ${LICENSE_FILE}, then start matlab-license-manager.service"
