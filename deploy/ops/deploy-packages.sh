#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEPLOY_TARGET="${DEPLOY_TARGET:-us1}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-https://api.easyfun.one/health}"

printf '\nUploading backend package to %s and restarting service...\n' "${DEPLOY_TARGET}"
DEPLOY_TARGET="${DEPLOY_TARGET}" "${SCRIPT_DIR}/deploy-backend.sh"

printf '\nUploading frontend package to %s and reloading nginx...\n' "${DEPLOY_TARGET}"
DEPLOY_TARGET="${DEPLOY_TARGET}" "${SCRIPT_DIR}/deploy-frontend.sh"

printf '\nRunning final health checks...\n'
ssh "${DEPLOY_TARGET}" curl -fsS http://127.0.0.1:8080/health
curl -fsS "${HEALTHCHECK_URL}" >/dev/null

printf '\nDeployment complete.\n'
