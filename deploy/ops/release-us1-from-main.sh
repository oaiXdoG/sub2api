#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEPLOY_TARGET="${DEPLOY_TARGET:-us1}"

run_step() {
  local label="$1"
  shift

  printf '\n=== %s ===\n' "${label}"
  if "$@"; then
    return 0
  else
    status=$?
    printf '\nERROR: 工作流在“%s”步骤停止，后续步骤未执行。\n' "${label}" >&2
    exit "${status}"
  fi
}

run_step "更新并同步代码" "${SCRIPT_DIR}/update-us1-from-main.sh"
run_step "构建发布包" "${SCRIPT_DIR}/build-packages.sh"
run_step "部署并健康检查" env DEPLOY_TARGET="${DEPLOY_TARGET}" "${SCRIPT_DIR}/deploy-packages.sh"

printf '\n发布工作流全部完成。\n'
