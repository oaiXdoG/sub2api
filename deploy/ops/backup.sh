#!/usr/bin/env bash

set -euo pipefail

DEPLOY_TARGET="${DEPLOY_TARGET:-}"
BACKUP_ROOT="${BACKUP_ROOT:-/root/sub2api-backups}"
BACKUP_DOWNLOAD_DIR="${BACKUP_DOWNLOAD_DIR:-}"
POSTGRES_DB="${POSTGRES_DB:-sub2api}"
POSTGRES_USER="${POSTGRES_USER:-sub2api}"
APP_DATA_DIR="${APP_DATA_DIR:-/opt/easyai/data}"
FRONTEND_DIR="${FRONTEND_DIR:-/opt/easyai/frontend_dist}"
CONFIG_FILE="${CONFIG_FILE:-/opt/easyai/data/config.yaml}"
NGINX_CONFIG="${NGINX_CONFIG:-/etc/nginx/conf.d/easyai.conf}"
INCLUDE_FRONTEND="${INCLUDE_FRONTEND:-0}"
INCLUDE_CERTS="${INCLUDE_CERTS:-0}"
KEEP_BACKUPS="${KEEP_BACKUPS:-0}"

run_backup_payload() {
  "$@" <<'BACKUP_SH'
set -eu

backup_base="$1"
postgres_db="$2"
postgres_user="$3"
app_data_dir="$4"
frontend_dir="$5"
config_file="$6"
nginx_config="$7"
include_frontend="$8"
include_certs="$9"
keep_backups="${10}"
ts="$(date +%Y%m%d-%H%M%S)"
backup_dir="${backup_base}/${ts}"
archive="${backup_base}/sub2api-backup-${ts}.tgz"

umask 077
mkdir -p "${backup_dir}"

printf 'Backup directory: %s\n' "${backup_dir}"
printf 'Backing up PostgreSQL with pg_dump...\n'
runuser -u postgres -- pg_dump -Fc -d "${postgres_db}" > "${backup_dir}/postgres.dump"

if [ ! -s "${backup_dir}/postgres.dump" ]; then
  printf 'PostgreSQL backup is empty.\n' >&2
  exit 1
fi

printf 'Collecting deployment files...\n'
file_list="${backup_dir}/files.list"
: > "${file_list}"

for path in "${config_file}" "${nginx_config}" "${app_data_dir}"; do
  if [ -e "${path}" ]; then
    printf '%s\n' "${path}" >> "${file_list}"
  fi
done

if [ "${include_certs}" = "1" ]; then
  for path in /opt/easyai/letsencrypt /opt/easyai/certbot; do
    if [ -e "${path}" ]; then
      printf '%s\n' "${path}" >> "${file_list}"
    fi
  done
fi

if [ "${include_frontend}" = "1" ] && [ -e "${frontend_dir}" ]; then
  printf '%s\n' "${frontend_dir}" >> "${file_list}"
fi

tar -czf "${backup_dir}/files.tgz" \
  --exclude="${app_data_dir}/logs" \
  -T "${file_list}" \
  2>/dev/null

{
  printf 'created_at=%s\n' "$(date -Iseconds)"
  printf 'postgres_db=%s\n' "${postgres_db}"
  printf 'postgres_user=%s\n' "${postgres_user}"
  printf 'app_data_dir=%s\n' "${app_data_dir}"
  printf 'config_file=%s\n' "${config_file}"
  printf 'nginx_config=%s\n' "${nginx_config}"
  printf 'include_certs=%s\n' "${include_certs}"
  printf 'include_frontend=%s\n' "${include_frontend}"
  printf 'archive=%s\n' "${archive}"
} > "${backup_dir}/manifest.txt"

(
  cd "${backup_dir}"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum postgres.dump files.tgz manifest.txt > SHA256SUMS
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 postgres.dump files.tgz manifest.txt > SHA256SUMS
  fi
)

printf 'Packing backup archive...\n'
tar -czf "${archive}" -C "${backup_base}" "${ts}"
rm -rf "${backup_dir}"
chmod 600 "${archive}"

if [ "${keep_backups}" != "0" ]; then
  find "${backup_base}" -maxdepth 1 -type f -name 'sub2api-backup-*.tgz' | sort -r | awk -v keep="${keep_backups}" 'NR > keep' | while IFS= read -r old_backup; do
    rm -f "${old_backup}"
  done
fi

printf 'Backup archive: %s\n' "${archive}"
printf 'BACKUP_ARCHIVE=%s\n' "${archive}"
BACKUP_SH
}

tmp_output="$(mktemp)"
trap 'rm -f "${tmp_output}"' EXIT

if [ -n "${DEPLOY_TARGET}" ]; then
  run_backup_payload ssh "${DEPLOY_TARGET}" 'sh -s' -- \
    "${BACKUP_ROOT}" "${POSTGRES_DB}" "${POSTGRES_USER}" "${APP_DATA_DIR}" "${FRONTEND_DIR}" "${CONFIG_FILE}" "${NGINX_CONFIG}" "${INCLUDE_FRONTEND}" "${INCLUDE_CERTS}" "${KEEP_BACKUPS}" | tee "${tmp_output}"
else
  run_backup_payload sh -s -- \
    "${BACKUP_ROOT}" "${POSTGRES_DB}" "${POSTGRES_USER}" "${APP_DATA_DIR}" "${FRONTEND_DIR}" "${CONFIG_FILE}" "${NGINX_CONFIG}" "${INCLUDE_FRONTEND}" "${INCLUDE_CERTS}" "${KEEP_BACKUPS}" | tee "${tmp_output}"
fi

backup_archive="$(awk -F= '/^BACKUP_ARCHIVE=/{print $2}' "${tmp_output}" | tail -n 1)"

if [ -n "${BACKUP_DOWNLOAD_DIR}" ]; then
  mkdir -p "${BACKUP_DOWNLOAD_DIR}"

  if [ -z "${backup_archive}" ]; then
    printf 'Unable to determine backup archive path.\n' >&2
    exit 1
  fi

  if [ -n "${DEPLOY_TARGET}" ]; then
    printf 'Downloading backup to: %s\n' "${BACKUP_DOWNLOAD_DIR}"
    scp "${DEPLOY_TARGET}:${backup_archive}" "${BACKUP_DOWNLOAD_DIR}/"
  else
    printf 'Copying backup to: %s\n' "${BACKUP_DOWNLOAD_DIR}"
    cp "${backup_archive}" "${BACKUP_DOWNLOAD_DIR}/"
  fi
fi
