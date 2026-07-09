#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '\nBuilding backend package...\n'
"${SCRIPT_DIR}/build-backend.sh"

printf '\nBuilding frontend package...\n'
"${SCRIPT_DIR}/build-frontend.sh"

printf '\nPackages ready:\n'
ls -lh "${SCRIPT_DIR}/../package"/sub2api-*.tar.gz
