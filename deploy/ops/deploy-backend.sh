#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEPLOY_TARGET="${DEPLOY_TARGET:?DEPLOY_TARGET is required, for example us1}"
ARCHIVE="${ARCHIVE:-${REPO_ROOT}/deploy/package/sub2api-backend.tar.gz}"
REMOTE_TMP="${REMOTE_TMP:-/tmp/sub2api-backend.tar.gz}"
INSTALL_DIR="${INSTALL_DIR:-/opt/sub2api}"
SERVICE_NAME="${SERVICE_NAME:-sub2api}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://127.0.0.1:8080/health}"
BUILD_BACKEND="${BUILD_BACKEND:-0}"

if [ "${BUILD_BACKEND}" = "1" ]; then
  "${SCRIPT_DIR}/build-backend.sh"
fi

if [ ! -f "${ARCHIVE}" ]; then
  printf 'Backend package is missing: %s\n' "${ARCHIVE}" >&2
  printf 'Run deploy/ops/build-backend.sh first, or set BUILD_BACKEND=1.\n' >&2
  exit 1
fi

printf 'Uploading backend package to %s:%s\n' "${DEPLOY_TARGET}" "${REMOTE_TMP}"
scp "${ARCHIVE}" "${DEPLOY_TARGET}:${REMOTE_TMP}"

ssh "${DEPLOY_TARGET}" 'sh -s' -- "${REMOTE_TMP}" "${INSTALL_DIR}" "${SERVICE_NAME}" "${HEALTHCHECK_URL}" <<'REMOTE'
set -eu

archive="$1"
install_dir="$2"
service_name="$3"
healthcheck_url="$4"
ts="$(date +%Y%m%d%H%M%S)"
release_dir="/tmp/sub2api-backend-${ts}"

mkdir -p "${release_dir}"
tar -xzf "${archive}" -C "${release_dir}"

if [ ! -x "${release_dir}/sub2api/sub2api" ]; then
  printf 'Invalid backend package: missing sub2api binary.\n' >&2
  exit 1
fi

systemctl stop "${service_name}"

if [ -f "${install_dir}/sub2api" ]; then
  cp -a "${install_dir}/sub2api" "${install_dir}/sub2api.backup.${ts}"
fi

install -d "${install_dir}"
install -m 0755 "${release_dir}/sub2api/sub2api" "${install_dir}/sub2api"
rm -rf "${install_dir}/resources"
cp -R "${release_dir}/sub2api/resources" "${install_dir}/resources"
chown -R sub2api:sub2api "${install_dir}"

systemctl start "${service_name}"
sleep 3
systemctl is-active "${service_name}" >/dev/null
curl -fsS "${healthcheck_url}" >/dev/null

rm -rf "${release_dir}"
rm -f "${archive}"

printf 'Backend deployed and healthy.\n'
REMOTE
