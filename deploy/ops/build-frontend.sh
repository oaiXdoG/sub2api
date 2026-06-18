#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_DEPS="${INSTALL_DEPS:-0}"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/deploy/package}"
ARCHIVE="${ARCHIVE:-${OUT_DIR}/sub2api-frontend.tar.gz}"

if [ "${INSTALL_DEPS}" = "1" ]; then
  pnpm --dir "${REPO_ROOT}/frontend" install --frozen-lockfile
fi

printf 'Building frontend static files into deploy/frontend_dist\n'
pnpm --dir "${REPO_ROOT}/frontend" run build:static

mkdir -p "${OUT_DIR}"
COPYFILE_DISABLE=1 tar --no-xattrs -C "${REPO_ROOT}/deploy/frontend_dist" -czf "${ARCHIVE}" .

printf 'Frontend package: %s\n' "${ARCHIVE}"
