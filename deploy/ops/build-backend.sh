#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/deploy/package}"
ARCHIVE="${ARCHIVE:-${OUT_DIR}/sub2api-backend.tar.gz}"
GOOS="${GOOS:-linux}"
GOARCH="${GOARCH:-amd64}"
CGO_ENABLED="${CGO_ENABLED:-0}"

mkdir -p "${OUT_DIR}"

printf 'Building backend binary...\n'
(
  cd "${REPO_ROOT}/backend"
  GOOS="${GOOS}" GOARCH="${GOARCH}" CGO_ENABLED="${CGO_ENABLED}" \
    go build -ldflags="${LDFLAGS:-"-s -w -X main.Version=$(tr -d '\r\n' < ./cmd/server/VERSION)"}" \
    -trimpath -o bin/server ./cmd/server
)

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

install -d "${tmp_dir}/sub2api"
install -m 0755 "${REPO_ROOT}/backend/bin/server" "${tmp_dir}/sub2api/sub2api"
cp -R "${REPO_ROOT}/backend/resources" "${tmp_dir}/sub2api/resources"

COPYFILE_DISABLE=1 tar --no-xattrs -C "${tmp_dir}" -czf "${ARCHIVE}" sub2api

printf 'Backend package: %s\n' "${ARCHIVE}"
