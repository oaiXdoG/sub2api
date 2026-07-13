#!/usr/bin/env bash

set -euo pipefail

DEPLOY_TARGET="${DEPLOY_TARGET:-us1}"
DB_NAME="${DB_NAME:-sub2api}"
INACTIVE_DAYS="${INACTIVE_DAYS:-7}"
PROTECTED_USER_IDS="${PROTECTED_USER_IDS:-6}"

usage() {
  cat <<'EOF'
Usage:
  ./deploy/ops/cleanup-users.sh

The script finds inactive users, displays them, and waits for confirmation before
deleting anything.

Environment:
  DEPLOY_TARGET   Database server SSH target (default: us1)
  DB_NAME         PostgreSQL database name (default: sub2api)
  INACTIVE_DAYS   Minimum account age and login inactivity (default: 7)
  PROTECTED_USER_IDS  Comma-separated IDs never selected (default: 6)
EOF
}

if [ "$#" -ne 0 ]; then
  case "${1}" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
fi

if [[ ! "${INACTIVE_DAYS}" =~ ^[1-9][0-9]*$ ]]; then
  printf 'INACTIVE_DAYS must be a positive integer.\n' >&2
  exit 2
fi

if [[ ! "${PROTECTED_USER_IDS}" =~ ^[1-9][0-9]*(,[1-9][0-9]*)*$ ]]; then
  printf 'PROTECTED_USER_IDS must be a comma-separated list of positive integers.\n' >&2
  exit 2
fi

find_candidate_ids() {
  ssh "${DEPLOY_TARGET}" bash -s -- \
    "${DB_NAME}" "${INACTIVE_DAYS}" "${PROTECTED_USER_IDS}" <<'REMOTE'
set -euo pipefail
db_name="$1"
inactive_days="$2"
protected_user_ids="$3"

sudo -u postgres psql -d "${db_name}" \
  -v ON_ERROR_STOP=1 \
  -v days="${inactive_days}" \
  -v protected_ids="${protected_user_ids}" \
  -At <<'SQL'
SELECT users.id
FROM users
WHERE users.deleted_at IS NULL
  AND users.role = 'user'
  AND users.id <> ALL(string_to_array(:'protected_ids', ',')::bigint[])
  AND users.created_at < NOW() - make_interval(days => :days)
  AND users.total_recharged = 0
  AND NOT EXISTS (
    SELECT 1
    FROM usage_logs
    WHERE usage_logs.user_id = users.id
  )
  AND (
    users.last_login_at IS NULL
    OR users.last_login_at < NOW() - make_interval(days => :days)
  )
ORDER BY users.id;
SQL
REMOTE
}

show_candidates() {
  ssh "${DEPLOY_TARGET}" bash -s -- "${DB_NAME}" "${candidate_csv}" <<'REMOTE'
set -euo pipefail
db_name="$1"
candidate_csv="$2"

sudo -u postgres psql -d "${db_name}" \
  -v ON_ERROR_STOP=1 \
  -v ids="${candidate_csv}" \
  -P pager=off <<'SQL'
SELECT
  users.id,
  users.email,
  users.created_at,
  users.last_login_at,
  users.total_recharged,
  (SELECT COUNT(*) FROM api_keys WHERE api_keys.user_id = users.id AND api_keys.deleted_at IS NULL) AS active_api_keys
FROM users
WHERE users.id = ANY(string_to_array(:'ids', ',')::bigint[])
ORDER BY users.id;
SQL
REMOTE
}

delete_candidates() {
  ssh "${DEPLOY_TARGET}" bash -s -- \
    "${DB_NAME}" "${INACTIVE_DAYS}" "${PROTECTED_USER_IDS}" \
    "${candidate_csv}" "${candidate_count}" <<'REMOTE'
set -euo pipefail
db_name="$1"
inactive_days="$2"
protected_user_ids="$3"
candidate_csv="$4"
candidate_count="$5"
redis_password="$(sed -n 's/^[[:space:]]*requirepass[[:space:]]\+//p' /etc/redis/redis.conf | tail -n 1)"
cache_hash_file="$(mktemp)"
trap 'rm -f "${cache_hash_file}"' EXIT INT TERM
chmod 600 "${cache_hash_file}"

# Keep only hashes needed for cache invalidation after the database transaction commits.
sudo -u postgres psql -d "${db_name}" -Atc \
  "SELECT key FROM api_keys WHERE user_id = ANY(string_to_array('${candidate_csv}', ',')::bigint[]) AND deleted_at IS NULL ORDER BY id" |
while IFS= read -r api_key; do
  [ -n "${api_key}" ] || continue
  printf '%s' "${api_key}" | sha256sum | awk '{print $1}' >> "${cache_hash_file}"
done

sudo -u postgres psql -d "${db_name}" \
  -v ON_ERROR_STOP=1 \
  -v days="${inactive_days}" \
  -v protected_ids="${protected_user_ids}" \
  -v ids="${candidate_csv}" \
  -v target_count="${candidate_count}" <<'SQL'
BEGIN;

CREATE TEMP TABLE delete_targets AS
SELECT users.id
FROM users
WHERE users.id = ANY(string_to_array(:'ids', ',')::bigint[])
  AND users.deleted_at IS NULL
  AND users.role = 'user'
  AND users.id <> ALL(string_to_array(:'protected_ids', ',')::bigint[])
  AND users.created_at < NOW() - make_interval(days => :days)
  AND users.total_recharged = 0
  AND NOT EXISTS (
    SELECT 1
    FROM usage_logs
    WHERE usage_logs.user_id = users.id
  )
  AND (
    users.last_login_at IS NULL
    OR users.last_login_at < NOW() - make_interval(days => :days)
  );

CREATE TEMP TABLE target_guard (
  valid boolean NOT NULL CHECK (valid)
);
INSERT INTO target_guard (valid)
SELECT COUNT(*) = :target_count
FROM delete_targets;

CREATE TEMP TABLE delete_keys AS
SELECT id, key, user_id, name
FROM api_keys
WHERE user_id IN (SELECT id FROM delete_targets)
  AND deleted_at IS NULL;

INSERT INTO deleted_api_key_audits (key, api_key_id, user_id, key_name, deleted_at)
SELECT key, id, user_id, name, NOW()
FROM delete_keys;

UPDATE api_keys
SET key = '__deleted__' || id || '__' || FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000000)::bigint,
    deleted_at = NOW(),
    updated_at = NOW()
WHERE id IN (SELECT id FROM delete_keys)
  AND deleted_at IS NULL;

UPDATE identity_adoption_decisions
SET identity_id = NULL
WHERE identity_id IN (
  SELECT auth_identities.id
  FROM auth_identities
  JOIN delete_targets ON delete_targets.id = auth_identities.user_id
);

DELETE FROM auth_identity_channels
WHERE identity_id IN (
  SELECT auth_identities.id
  FROM auth_identities
  JOIN delete_targets ON delete_targets.id = auth_identities.user_id
);

DELETE FROM auth_identities
WHERE user_id IN (SELECT id FROM delete_targets);

UPDATE users
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id IN (SELECT id FROM delete_targets)
  AND deleted_at IS NULL;

COMMIT;

SELECT
  (SELECT COUNT(*) FROM users WHERE id = ANY(string_to_array(:'ids', ',')::bigint[]) AND deleted_at IS NULL) AS active_target_users,
  (SELECT COUNT(*) FROM api_keys WHERE user_id = ANY(string_to_array(:'ids', ',')::bigint[]) AND deleted_at IS NULL) AS active_target_keys,
  (SELECT COUNT(*) FROM auth_identities WHERE user_id = ANY(string_to_array(:'ids', ',')::bigint[])) AS remaining_identities,
  (SELECT COUNT(*) FROM users WHERE role = 'user' AND deleted_at IS NULL) AS active_normal_users;
SQL

while IFS= read -r key_hash; do
  [ -n "${key_hash}" ] || continue
  REDISCLI_AUTH="${redis_password}" redis-cli DEL "apikey:auth:${key_hash}" >/dev/null
  REDISCLI_AUTH="${redis_password}" redis-cli PUBLISH "auth:cache:invalidate" "${key_hash}" >/dev/null
done < "${cache_hash_file}"

IFS=',' read -r -a ids <<< "${candidate_csv}"
for user_id in "${ids[@]}"; do
  REDISCLI_AUTH="${redis_password}" redis-cli --raw SMEMBERS "user_refresh_tokens:${user_id}" |
  while IFS= read -r token_hash; do
    [ -n "${token_hash}" ] || continue
    REDISCLI_AUTH="${redis_password}" redis-cli DEL "refresh_token:${token_hash}" >/dev/null
  done
  REDISCLI_AUTH="${redis_password}" redis-cli DEL \
    "user_refresh_tokens:${user_id}" \
    "apikey:ratelimit:${user_id}" >/dev/null
done
REMOTE
}

printf 'Scanning %s for inactive users (older than %s days, protected IDs: %s)...\n' \
  "${DEPLOY_TARGET}" "${INACTIVE_DAYS}" "${PROTECTED_USER_IDS}"

candidate_ids="$(find_candidate_ids)"
if [ -z "${candidate_ids}" ]; then
  printf 'No users match the cleanup conditions.\n'
  exit 0
fi

candidate_csv="$(printf '%s\n' "${candidate_ids}" | paste -sd, -)"
candidate_count="$(printf '%s\n' "${candidate_ids}" | awk 'NF { count++ } END { print count + 0 }')"

printf '\nMatched users: %s\n\n' "${candidate_count}"
show_candidates

printf '\nDelete these %s users? Enter y to confirm [y/N]: ' "${candidate_count}"
answer=""
IFS= read -r answer || true
case "${answer}" in
  y|Y)
    ;;
  *)
    printf 'Cleanup cancelled. No data was changed.\n'
    exit 0
    ;;
esac

printf '\nDeleting matched users...\n'
delete_candidates
printf '\nCleanup completed. Deleted users: %s\n' "${candidate_count}"
