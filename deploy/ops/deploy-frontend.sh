#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DEPLOY_TARGET="${DEPLOY_TARGET:?DEPLOY_TARGET is required, for example us1}"
LOCAL_FRONTEND_DIST="${LOCAL_FRONTEND_DIST:-${REPO_ROOT}/deploy/frontend_dist}"
ARCHIVE="${ARCHIVE:-${REPO_ROOT}/deploy/package/sub2api-frontend.tar.gz}"
REMOTE_TMP="${REMOTE_TMP:-/tmp/sub2api-frontend.tar.gz}"
REMOTE_FRONTEND_DIR="${REMOTE_FRONTEND_DIR:-/opt/easyai/frontend_dist}"
NGINX_SERVICE="${NGINX_SERVICE:-nginx}"
BUILD_FRONTEND="${BUILD_FRONTEND:-0}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-https://api.easyfun.one/health}"

if [ "${BUILD_FRONTEND}" = "1" ]; then
  "${SCRIPT_DIR}/build-frontend.sh"
fi

if [ ! -f "${LOCAL_FRONTEND_DIST}/index.html" ]; then
  printf 'Frontend dist is missing: %s\n' "${LOCAL_FRONTEND_DIST}" >&2
  printf 'Run deploy/ops/build-frontend.sh first, or set BUILD_FRONTEND=1.\n' >&2
  exit 1
fi

if [ ! -f "${ARCHIVE}" ]; then
  printf 'Frontend package is missing: %s\n' "${ARCHIVE}" >&2
  printf 'Run deploy/ops/build-frontend.sh first, or set BUILD_FRONTEND=1.\n' >&2
  exit 1
fi

printf 'Uploading frontend package to %s:%s\n' "${DEPLOY_TARGET}" "${REMOTE_TMP}"
scp "${ARCHIVE}" "${DEPLOY_TARGET}:${REMOTE_TMP}"

ssh "${DEPLOY_TARGET}" 'sh -s' -- "${REMOTE_FRONTEND_DIR}" "${REMOTE_TMP}" <<'REMOTE'
set -eu
frontend_dir="$1"
archive="$2"
mkdir -p "${frontend_dir}"
find "${frontend_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
tar -C "${frontend_dir}" -xzf "${archive}"
rm -f "${archive}"
REMOTE

ssh "${DEPLOY_TARGET}" 'sh -s' -- "${NGINX_SERVICE}" "${HEALTHCHECK_URL}" <<'REMOTE'
set -eu
service_name="$1"
healthcheck_url="$2"
nginx -t
systemctl reload "${service_name}"
curl -k -fsS "${healthcheck_url}" >/dev/null
REMOTE

printf 'Frontend deployed and nginx reloaded.\n'
