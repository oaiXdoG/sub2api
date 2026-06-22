# Sub2API Host Deployment

This directory is for the current host-based deployment only. The production layout uses systemd-managed services on the host:

- `sub2api` backend service
- `nginx`
- `postgresql`
- `redis-server`

Docker deployment files have been removed from this branch.

## Main Files

| File | Description |
|------|-------------|
| `ops/` | Build, deploy, and backup scripts for the host deployment |
| `ops/README.md` | Operational release workflow |
| `sub2api.service` | systemd service unit for the backend |
| `install.sh` | Binary install helper for a host deployment |
| `install-datamanagementd.sh` | datamanagementd install helper |
| `sub2api-datamanagementd.service` | systemd service unit for datamanagementd |
| `DATAMANAGEMENTD_CN.md` | datamanagementd host deployment notes |
| `config.example.yaml` | Example application configuration |
| `Caddyfile` | Optional host reverse-proxy example |

## Build Packages

From the repository root:

```bash
./deploy/ops/build-backend.sh
./deploy/ops/build-frontend.sh
```

Outputs:

```text
deploy/package/sub2api-backend.tar.gz
deploy/package/sub2api-frontend.tar.gz
```

## Deploy

Set the SSH target and deploy:

```bash
DEPLOY_TARGET=us1 ./deploy/ops/deploy-all.sh
```

Deploy only one side:

```bash
DEPLOY_TARGET=us1 ./deploy/ops/deploy-backend.sh
DEPLOY_TARGET=us1 ./deploy/ops/deploy-frontend.sh
```

See `deploy/ops/README.md` for paths, optional variables, and backup commands.
