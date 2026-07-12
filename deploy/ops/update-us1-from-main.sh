#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MAIN_BRANCH="${MAIN_BRANCH:-main}"
WORK_BRANCH="${WORK_BRANCH:-my-main}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-git@github.com:Wei-Shaw/sub2api.git}"
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"
RUN_TESTS="${RUN_TESTS:-0}"

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

run() {
  printf '+ %s\n' "$*"
  "$@"
}

cd "${REPO_ROOT}"

if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
  fail "当前仓库已经处于 merge 中，请先处理完冲突再运行。"
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  fail "当前存在已跟踪文件改动。为避免覆盖你的修改，请先提交或还原后再运行。"
fi

untracked_count="$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
if [ "${untracked_count}" != "0" ]; then
  log "检测到 ${untracked_count} 个未跟踪文件；脚本会保留它们，但不会打包进 Git 合并。"
fi

start_branch="$(git branch --show-current)"
log "当前分支: ${start_branch:-unknown}"

if git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
  log "使用上游仓库: ${UPSTREAM_REMOTE} ($(git remote get-url "${UPSTREAM_REMOTE}"))"
else
  log "添加上游仓库: ${UPSTREAM_REMOTE} -> ${UPSTREAM_URL}"
  run git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
fi

log "从官方仓库获取 ${UPSTREAM_REMOTE}/${MAIN_BRANCH}"
run git fetch "${UPSTREAM_REMOTE}" "${MAIN_BRANCH}"

log "更新本地 ${MAIN_BRANCH}"
run git switch "${MAIN_BRANCH}"
run git merge --ff-only "${UPSTREAM_REMOTE}/${MAIN_BRANCH}"

log "推送 ${MAIN_BRANCH} 到 Fork 仓库 ${ORIGIN_REMOTE}/${MAIN_BRANCH}"
run git push "${ORIGIN_REMOTE}" "${MAIN_BRANCH}:${MAIN_BRANCH}"

log "切回 ${WORK_BRANCH} 并合并 ${MAIN_BRANCH}"
run git switch "${WORK_BRANCH}"

set +e
git merge --no-edit "${MAIN_BRANCH}"
merge_status=$?
set -e

if [ "${merge_status}" -ne 0 ]; then
  printf '\n合并发生冲突，已停止。冲突文件如下：\n' >&2
  git diff --name-only --diff-filter=U >&2 || true
  printf '\n请手动处理冲突后执行 git add / git commit，再重新运行打包部署步骤。\n' >&2
  exit "${merge_status}"
fi

if [ "${RUN_TESTS}" = "1" ]; then
  log "运行测试"
  run make test
fi

log "更新完成，当前提交"
git log --oneline -1
