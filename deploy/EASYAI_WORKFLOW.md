# easyAI 二开流程

本文档记录当前仓库的二开、更新和部署流程。线上发布以 `my-main` 分支为准。

## 分支约定

```text
main      跟随上游仓库，尽量保持干净
my-main   自己的线上发布分支
ui        界面、主题、文案等前端二开分支
feature/* 其他独立功能分支
```

日常开发先在功能分支提交，确认后合并到 `my-main`。线上只从 `my-main` 构建和部署。

## 开发流程

开始前确认分支：

```bash
git status
git switch ui
```

前端本地开发：

```bash
cd frontend
pnpm install
pnpm run dev
```

完成后检查并提交：

```bash
git status
git add frontend/src frontend/package.json frontend/tailwind.config.js
git commit -m "feat: customize easyAI frontend"
```

部署配置改动单独提交：

```bash
git add deploy .gitignore Dockerfile .dockerignore
git commit -m "chore: document easyAI deployment workflow"
```

## 合并到发布分支

```bash
git switch my-main
git merge ui
```

如有冲突，按当前二开方案保留 easyAI 的前端和部署配置，解决后继续：

```bash
git add <resolved-files>
git commit
```

## 同步上游更新

先更新干净的 `main`：

```bash
git switch main
git pull upstream main
```

再同步到自己的发布分支：

```bash
git switch my-main
git merge main
```

如果功能分支还要继续开发，再让功能分支追上 `my-main`：

```bash
git switch ui
git merge my-main
```

## 当前部署结构

线上采用 4 个独立容器：

```text
nginx       对外 80/443，提供 HTTPS、前端静态文件、API 反代
sub2api-api 后端 API / 网关，仅 Docker 内网
postgres    数据库，仅 Docker 内网
redis       缓存，仅 Docker 内网
```

生产目录固定为：

```text
/opt/easyai
```

重要数据目录：

```text
/opt/easyai/postgres_data
/opt/easyai/redis_data
/opt/easyai/data
/opt/easyai/letsencrypt
/opt/easyai/frontend_dist
/opt/easyai/nginx
/opt/easyai/.env
```

迁移时必须保留 `postgres_data`、`redis_data`、`data`、`letsencrypt` 和 `.env`。

## 仅前端更新

适用范围：主题、页面、菜单、文案、前端交互。

```bash
git switch my-main
pnpm --dir frontend run build:static
COPYFILE_DISABLE=1 tar --no-xattrs -C deploy/frontend_dist -czf /tmp/easyai-frontend-dist-clean.tar.gz .
scp /tmp/easyai-frontend-dist-clean.tar.gz us1:/tmp/easyai-frontend-dist-clean.tar.gz
ssh us1 'set -eu; rm -rf /opt/easyai/frontend_dist/*; tar --no-same-owner -xzf /tmp/easyai-frontend-dist-clean.tar.gz -C /opt/easyai/frontend_dist; find /opt/easyai/frontend_dist -name "._*" -delete; cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml restart nginx'
```

这种情况不需要重启 `sub2api-api`、`postgres`、`redis`。

## 后端更新

适用范围：Go 后端代码、后端依赖、数据库迁移、API 行为变化。

如果继续使用镜像部署，先构建并推送新的后端镜像，然后更新服务器 `.env` 中的 `SUB2API_IMAGE`，再执行：

```bash
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml pull sub2api-api && docker compose --env-file .env -f docker-compose.yml up -d sub2api-api'
```

后端更新一般不需要动 `postgres` 和 `redis` 容器，除非明确升级数据库或 Redis 版本。

## 首次部署或配置变更

生产配置文件：

```text
deploy/docker-compose.prod.yml
deploy/nginx/sub2api-prod.conf
deploy/nginx/sub2api-http-bootstrap.conf
```

服务器对应路径：

```text
/opt/easyai/docker-compose.yml
/opt/easyai/nginx/sub2api-prod.conf
```

`.env` 只在服务器生成和维护，不提交到仓库。公网只开放 `80` 和 `443`，不要开放 `5432`、`6379`、`8080`。

## 验证

```bash
curl -I https://api.easyfun.one/
curl -fsS https://api.easyfun.one/health
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml ps'
```

如果只更新前端，确认浏览器强刷后页面变化即可。若静态资源缓存异常，优先检查 `/opt/easyai/frontend_dist` 是否已替换。
