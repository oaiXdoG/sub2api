#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEPLOY_TARGET="${DEPLOY_TARGET:-us1}"

"${SCRIPT_DIR}/update-us1-from-main.sh"
"${SCRIPT_DIR}/build-packages.sh"
DEPLOY_TARGET="${DEPLOY_TARGET}" "${SCRIPT_DIR}/deploy-packages.sh"
