# easyAI 分离部署说明

本文档只记录当前部署方式和运维信息。业务配置，例如邮箱、注册、套餐等，不写在这里。

## 部署结构

当前采用 4 个核心容器：

| 容器 | 作用 | 是否对外暴露 |
| --- | --- | --- |
| `easyai-nginx` | HTTPS、静态前端、反向代理后端 | 是，`80`/`443` |
| `easyai-api` | sub2api 后端 API / 网关 | 否，仅 Docker 内网 |
| `easyai-postgres` | PostgreSQL 数据库 | 否，仅 Docker 内网 |
| `easyai-redis` | Redis 缓存 | 否，仅 Docker 内网 |

生产部署文件：

```text
deploy/docker-compose.prod.yml
deploy/nginx/sub2api-prod.conf
```

本地开发部署文件：

```text
deploy/docker-compose.split.yml
deploy/nginx/sub2api-split.conf
```

## 数据目录

生产服务器建议固定部署在：

```text
/opt/easyai
```

重要持久化目录如下，迁移或备份时重点保留：

```text
/opt/easyai/postgres_data/     PostgreSQL 数据目录
/opt/easyai/redis_data/        Redis AOF/RDB 数据目录
/opt/easyai/data/              sub2api 后端应用数据
/opt/easyai/frontend_dist/     前端静态构建产物，可重新构建
/opt/easyai/letsencrypt/       HTTPS 证书目录
/opt/easyai/certbot/www/       Certbot HTTP 验证目录
/opt/easyai/nginx/             Nginx 配置目录
/opt/easyai/.env               生产环境变量和密钥
```

`postgres_data/`、`redis_data/`、`data/`、`letsencrypt/` 不要随意删除。

## 端口策略

公网只开放：

```text
80/tcp
443/tcp
```

不开放：

```text
5432 PostgreSQL
6379 Redis
8080 sub2api-api
```

后端、数据库、Redis 只通过 Docker bridge 网络互通。

## 生产环境变量

生产 `.env` 必须使用强密码和随机密钥，不能使用本地开发默认值。

关键字段：

```text
POSTGRES_USER=sub2api
POSTGRES_PASSWORD=强随机密码
POSTGRES_DB=sub2api
REDIS_PASSWORD=强随机密码
ADMIN_EMAIL=管理员邮箱
ADMIN_PASSWORD=强随机密码
JWT_SECRET=64字节以上随机字符串
TOTP_ENCRYPTION_KEY=32字节随机值的 hex 字符串，也就是 64 个 hex 字符
SERVER_MODE=release
TZ=Asia/Shanghai
```

## 首次生产部署

本地构建前端：

```bash
pnpm --dir frontend run build:static
```

服务器创建目录：

```bash
sudo mkdir -p /opt/easyai/{nginx,frontend_dist,certbot/www,letsencrypt,postgres_data,redis_data,data}
```

上传以下内容到服务器：

```text
deploy/docker-compose.prod.yml -> /opt/easyai/docker-compose.yml
deploy/nginx/sub2api-prod.conf -> /opt/easyai/nginx/sub2api-prod.conf
deploy/frontend_dist/          -> /opt/easyai/frontend_dist/
/opt/easyai/.env               -> 服务器生成，不上传本地弱密码
```

启动前需要确认 DNS：

```text
api.easyfun.one A 服务器公网 IP
```

## HTTPS

当前选择 `Nginx + Certbot`。

首次签发证书时，需要先让 Nginx 使用 HTTP 配置响应 `/.well-known/acme-challenge/`，再运行 Certbot。证书签发后启用 `443` 配置。

证书目录：

```text
/opt/easyai/letsencrypt/live/api.easyfun.one/
```

续期命令：

```bash
docker compose --env-file /opt/easyai/.env -f /opt/easyai/docker-compose.yml --profile certbot run --rm certbot renew
docker compose --env-file /opt/easyai/.env -f /opt/easyai/docker-compose.yml restart nginx
```

## 日常更新前端

只改界面、样式、菜单、文案时，本地构建并同步静态文件：

```bash
pnpm --dir frontend run build:static
rsync -av --delete deploy/frontend_dist/ us1:/opt/easyai/frontend_dist/
```

通常不需要重启后端。必要时只重启 Nginx：

```bash
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml restart nginx'
```

## 更新后端镜像

只有后端镜像变更时执行：

```bash
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml pull sub2api-api && docker compose --env-file .env -f docker-compose.yml up -d sub2api-api'
```

## 常用排查

查看容器：

```bash
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml ps'
```

查看日志：

```bash
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml logs -f nginx'
ssh us1 'cd /opt/easyai && docker compose --env-file .env -f docker-compose.yml logs -f sub2api-api'
```

检查 HTTPS：

```bash
curl -I https://api.easyfun.one/
curl -fsS https://api.easyfun.one/health
```

如果本地 DNS 还未刷新，可临时指定解析验证：

```bash
curl --resolve api.easyfun.one:443:服务器公网IP -I https://api.easyfun.one/
```

检查公网端口：

```bash
ssh us1 'ss -lntp'
```
