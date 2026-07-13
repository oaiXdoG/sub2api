# 宿主机部署发布脚本

这些脚本匹配当前宿主机部署方式：`nginx`、`sub2api`、`postgresql`、`redis-server` 都由宿主机 systemd 管理，不使用 Docker。

当前线上约定：

```text
后端服务：sub2api
后端目录：/opt/sub2api
应用数据：/opt/easyai/data
前端目录：/opt/easyai/frontend_dist
Nginx 配置：/etc/nginx/conf.d/easyai.conf
```

## 通用变量

```bash
export DEPLOY_TARGET=us1
```

## 1. 打包后端服务

```bash
./deploy/ops/build-backend.sh
```

产物：`deploy/package/sub2api-backend.tar.gz`

## 2. 打包前端项目

```bash
./deploy/ops/build-frontend.sh
```

首次或依赖变化时：

```bash
INSTALL_DEPS=1 ./deploy/ops/build-frontend.sh
```

产物：`deploy/package/sub2api-frontend.tar.gz`

## 3. 更新部署前端

```bash
DEPLOY_TARGET=us1 ./deploy/ops/deploy-frontend.sh
```

如需部署前自动编译：

```bash
BUILD_FRONTEND=1 DEPLOY_TARGET=us1 ./deploy/ops/deploy-frontend.sh
```

## 4. 更新部署后端

```bash
DEPLOY_TARGET=us1 ./deploy/ops/deploy-backend.sh
```

如需部署前自动编译：

```bash
BUILD_BACKEND=1 DEPLOY_TARGET=us1 ./deploy/ops/deploy-backend.sh
```

## 5. 前后端一起更新发布

```bash
DEPLOY_TARGET=us1 ./deploy/ops/deploy-all.sh
```

顺序：打包后端、打包前端、发布后端、发布前端。

## 6. 从 main 同步、构建、部署

这些脚本按职责拆开，可以单独运行，也可以一键串起来。

同步官方仓库、更新 Fork 的 `main`，并合并到本地工作分支：

```bash
./deploy/ops/update-us1-from-main.sh
```

顺序：检查工作区、拉取官方 `upstream/main`、快进本地 `main`、推送到 Fork 的 `origin/main`、切回 `my-main` 合并并推送到 `origin/my-main`。
首次运行时会自动添加 `upstream` 远程仓库，不再需要在 GitHub 页面点击 `Sync fork`。
如果有冲突会立刻停止并列出冲突文件。

只构建本地发布包：

```bash
./deploy/ops/build-packages.sh
```

只上传已经构建好的包，并重启/重载服务：

```bash
DEPLOY_TARGET=us1 ./deploy/ops/deploy-packages.sh
```

一键完整执行：

```bash
DEPLOY_TARGET=us1 ./deploy/ops/release-us1-from-main.sh
```

顺序：同步 `main` 到 `my-main`、构建前后端包、上传到 `us1` 并重启/重载服务。

## 7. 备份

备份默认保存在目标机器 `/root/sub2api-backups/` 下。

默认精简备份内容：

- PostgreSQL：`pg_dump -Fc` 逻辑备份
- `/opt/easyai/data`，排除 `logs`
- `/etc/nginx/conf.d/easyai.conf`

默认不备份：

- `frontend_dist/`：可以重新编译发布
- `letsencrypt/`、`certbot/`：迁移服务器时再备

远程备份：

```bash
DEPLOY_TARGET=us1 ./deploy/ops/backup.sh
```

远程备份并下载一份到本机：

```bash
BACKUP_DOWNLOAD_DIR=./backups DEPLOY_TARGET=us1 ./deploy/ops/backup.sh
```

只保留最近 10 份：

```bash
KEEP_BACKUPS=10 DEPLOY_TARGET=us1 ./deploy/ops/backup.sh
```

需要更完整的迁移备份时再打开可选项：

```bash
INCLUDE_CERTS=1 INCLUDE_FRONTEND=1 DEPLOY_TARGET=us1 ./deploy/ops/backup.sh
```

## 常用可选项

```bash
export HEALTHCHECK_URL=https://example.com/health
export BACKUP_DOWNLOAD_DIR=./backups
export INCLUDE_CERTS=1
export INCLUDE_FRONTEND=1
export KEEP_BACKUPS=10
```

## 8. 清理垃圾账号

直接运行交互式清理脚本：

```bash
./deploy/ops/cleanup-users.sh
```

脚本自动筛选同时满足以下条件的账号：

1. 尚未删除的普通用户。
2. 注册时间超过 7 天。
3. 没有任何用量记录。
4. 累计充值金额为 0。
5. 从未登录，或者最后登录时间超过 7 天。
6. 不在保护名单中；根据现有清理约定，默认保护用户 ID `6`。

脚本会展示符合条件的账号、注册时间、最后登录时间和有效 API Key 数量，然后等待输入。只有输入 `y` 并回车才会删除；其他输入或直接回车都会取消，且不修改数据。

确认后执行以下操作：API Key 写入删除审计并软删除、登录身份删除、用户软删除、认证缓存和刷新令牌清理。API Key 不属于豁免条件；用量、充值和订单历史继续保留用于审计。该流程不创建备份，也不处理 Nginx、防火墙或 IP 黑名单。

默认阈值为 7 天，需要调整时使用：

```bash
INACTIVE_DAYS=14 ./deploy/ops/cleanup-users.sh
```

默认保护名单为 `6`，多个 ID 使用逗号分隔：

```bash
PROTECTED_USER_IDS=6,100 ./deploy/ops/cleanup-users.sh
```
