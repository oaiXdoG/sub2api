#!/usr/bin/env bash

set -euo pipefail

ARCHIVE_ROOT="${ARCHIVE_ROOT:-/etc/archive}"
INCOMING_DIR="${INCOMING_DIR:-${ARCHIVE_ROOT}/incoming}"
RETENTION_MINUTES="${RETENTION_MINUTES:-2880}"
LOCK_FILE="${LOCK_FILE:-/run/archive-destination.lock}"

umask 077
install -d -m 0700 "${ARCHIVE_ROOT}" "${INCOMING_DIR}"

exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  printf 'Another archive run is still active.\n'
  exit 0
fi

archive_incoming() {
  local sha_path sha_name backup_id archive_name archive_date target_dir

  shopt -s nullglob
  for sha_path in "${INCOMING_DIR}"/*.sha256; do
    sha_name="$(basename "${sha_path}")"
    backup_id="${sha_name%.sha256}"
    archive_name="${backup_id}.tar.gz"

    if [[ ! "${backup_id}" =~ ^([0-9]{8})-[0-9]{6}-[0-9a-f]{8}$ ]]; then
      printf 'Invalid backup filename: %s\n' "${sha_name}" >&2
      continue
    fi

    if [ ! -s "${INCOMING_DIR}/${archive_name}" ]; then
      printf 'Missing backup archive for %s\n' "${sha_name}" >&2
      continue
    fi

    (
      cd "${INCOMING_DIR}"
      sha256sum -c "${sha_name}"
    )

    archive_date="${BASH_REMATCH[1]}"
    target_dir="${ARCHIVE_ROOT}/${archive_date}"
    install -d -m 0700 "${target_dir}"
    tar -tzf "${INCOMING_DIR}/${archive_name}" >/dev/null
    mv "${INCOMING_DIR}/${archive_name}" "${target_dir}/${archive_name}"
    mv "${sha_path}" "${target_dir}/${sha_name}"
    printf 'Archived backup: %s/%s\n' "${archive_date}" "${backup_id}"
  done
}

prune_expired() {
  find "${ARCHIVE_ROOT}" \
    -mindepth 2 \
    -maxdepth 2 \
    -type f \
    \( -name '*.tar.gz' -o -name '*.sha256' \) \
    -mmin "+${RETENTION_MINUTES}" \
    -delete

  find "${ARCHIVE_ROOT}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -name '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' \
    -empty \
    -delete

  find "${INCOMING_DIR}" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -name '.staging-*' \
    -mmin +1440 \
    -exec rm -rf -- {} +
}

archive_incoming
prune_expired
