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

## 6. 备份

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
