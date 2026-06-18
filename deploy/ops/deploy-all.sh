#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/build-backend.sh"
"${SCRIPT_DIR}/build-frontend.sh"
"${SCRIPT_DIR}/deploy-backend.sh"
"${SCRIPT_DIR}/deploy-frontend.sh"
