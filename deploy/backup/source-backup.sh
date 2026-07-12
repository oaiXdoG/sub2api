#!/usr/bin/env bash

set -euo pipefail

DB_NAME="${DB_NAME:-sub2api}"
SPOOL_DIR="${SPOOL_DIR:-/etc/archive/spool}"
REMOTE_TARGET="${REMOTE_TARGET:-us}"
REMOTE_INCOMING="${REMOTE_INCOMING:-/etc/archive/incoming}"
LOCK_FILE="${LOCK_FILE:-/run/archive-source-backup.lock}"

umask 077
install -d -m 0700 "${SPOOL_DIR}"

exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  printf 'Another backup run is still active.\n'
  exit 0
fi

work_dir=""

cleanup() {
  if [ -n "${work_dir}" ] && [ -d "${work_dir}" ]; then
    rm -rf "${work_dir}"
  fi
}
trap cleanup EXIT INT TERM

create_backup() {
  local timestamp random_id backup_id archive_name sha_name tmp_archive

  timestamp="$(TZ=Asia/Shanghai date +%Y%m%d-%H%M%S)"
  random_id="$(openssl rand -hex 4)"
  backup_id="${timestamp}-${random_id}"
  archive_name="${backup_id}.tar.gz"
  sha_name="${backup_id}.sha256"
  tmp_archive="${SPOOL_DIR}/.${archive_name}.tmp"
  work_dir="$(mktemp -d "${SPOOL_DIR}/.work.XXXXXX")"

  printf 'Creating PostgreSQL dump: %s\n' "${backup_id}"
  runuser -u postgres -- pg_dump \
    --format=custom \
    --no-owner \
    --no-acl \
    "${DB_NAME}" > "${work_dir}/database.dump"

  test -s "${work_dir}/database.dump"
  pg_restore --list "${work_dir}/database.dump" >/dev/null

  {
    printf 'created_at=%s\n' "$(TZ=Asia/Shanghai date --iso-8601=seconds)"
    printf 'database=%s\n' "${DB_NAME}"
    printf 'format=pg_dump_custom\n'
    printf 'postgres_version=%s\n' "$(runuser -u postgres -- pg_dump --version)"
    printf 'dump_sha256=%s\n' "$(sha256sum "${work_dir}/database.dump" | awk '{print $1}')"
  } > "${work_dir}/manifest.txt"

  tar -C "${work_dir}" -czf "${tmp_archive}" database.dump manifest.txt
  test -s "${tmp_archive}"
  tar -tzf "${tmp_archive}" >/dev/null
  mv "${tmp_archive}" "${SPOOL_DIR}/${archive_name}"
  (
    cd "${SPOOL_DIR}"
    sha256sum "${archive_name}" > "${sha_name}"
  )

  rm -rf "${work_dir}"
  work_dir=""
}

upload_pending() {
  local sha_path sha_name backup_id archive_name stage

  shopt -s nullglob
  for sha_path in "${SPOOL_DIR}"/*.sha256; do
    sha_name="$(basename "${sha_path}")"
    backup_id="${sha_name%.sha256}"
    archive_name="${backup_id}.tar.gz"
    stage=".staging-${backup_id}"

    if [ ! -s "${SPOOL_DIR}/${archive_name}" ]; then
      printf 'Missing backup archive for %s\n' "${sha_name}" >&2
      continue
    fi

    printf 'Uploading backup: %s\n' "${backup_id}"
    ssh "${REMOTE_TARGET}" sh -s -- "${REMOTE_INCOMING}" "${stage}" <<'REMOTE_PREPARE'
set -eu
incoming="$1"
stage="$2"
umask 077
mkdir -p "${incoming}"
rm -rf "${incoming:?}/${stage}"
mkdir "${incoming}/${stage}"
REMOTE_PREPARE

    scp \
      "${SPOOL_DIR}/${archive_name}" \
      "${sha_path}" \
      "${REMOTE_TARGET}:${REMOTE_INCOMING}/${stage}/"

    ssh "${REMOTE_TARGET}" sh -s -- \
      "${REMOTE_INCOMING}" "${stage}" "${archive_name}" "${sha_name}" <<'REMOTE_COMMIT'
set -eu
incoming="$1"
stage="$2"
archive_name="$3"
sha_name="$4"
cd "${incoming}/${stage}"
sha256sum -c "${sha_name}"
test -s "${archive_name}"
tar -tzf "${archive_name}" >/dev/null
mv "${archive_name}" "${incoming}/${archive_name}"
mv "${sha_name}" "${incoming}/${sha_name}"
cd "${incoming}"
rmdir "${stage}"
REMOTE_COMMIT

    rm -f "${SPOOL_DIR}/${archive_name}" "${sha_path}"
    printf 'Upload verified: %s\n' "${backup_id}"
  done
}

create_backup
upload_pending
