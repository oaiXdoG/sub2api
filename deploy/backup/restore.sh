#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'Usage: CONFIRM_RESTORE=1 %s /etc/archive/YYYYMMDD/<backup>.tar.gz\n' "$0" >&2
  exit 2
fi

if [ "${CONFIRM_RESTORE:-0}" != "1" ]; then
  printf 'Set CONFIRM_RESTORE=1 to allow database restore.\n' >&2
  exit 2
fi

archive="$1"
checksum="${archive%.tar.gz}.sha256"
db_name="${DB_NAME:-sub2api}"
work_dir="$(mktemp -d /tmp/archive-restore.XXXXXX)"

cleanup() {
  rm -rf "${work_dir}"
}
trap cleanup EXIT INT TERM

test -s "${archive}"
test -s "${checksum}"
(
  cd "$(dirname "${archive}")"
  sha256sum -c "$(basename "${checksum}")"
)

tar -xzf "${archive}" -C "${work_dir}"

test -s "${work_dir}/database.dump"
pg_restore --list "${work_dir}/database.dump" >/dev/null
chown postgres:postgres "${work_dir}" "${work_dir}/database.dump"
chmod 0700 "${work_dir}"

printf 'Restoring database: %s\n' "${db_name}"
runuser -u postgres -- pg_restore \
  --exit-on-error \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl \
  --dbname="${db_name}" \
  "${work_dir}/database.dump"

printf 'Restore completed: %s\n' "${db_name}"
