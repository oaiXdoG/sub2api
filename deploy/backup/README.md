# 数据库异机备份指引

## 1. 备份范围

只备份 PostgreSQL 的 `sub2api` 数据库，不备份 Redis、应用配置、日志、程序文件或部署环境。

压缩包内部包含：

```text
database.dump
manifest.txt
```

## 2. 服务器职责

- `us1`：每小时生成 PostgreSQL custom-format dump，检查后压缩打包并上传。
- `us`：校验文件，按日期归档，滚动保留最近 48 小时。

目录及命名：

```text
/etc/archive/YYYYMMDD/YYYYMMDD-HHMMSS-<8位随机值>.tar.gz
/etc/archive/YYYYMMDD/YYYYMMDD-HHMMSS-<8位随机值>.sha256
```

文件名不包含项目名、数据库名或环境名。

## 3. SSH

`us1` 使用专用密钥 `/root/.ssh/id_ed25519_us_backup` 连接 SSH 别名 `us`。公钥在 `us` 上限制来源 IP，并禁用 PTY 和端口转发。

验证：

```bash
ssh us true
```

## 4. 定时任务

脚本安装位置：

```text
# us1
/usr/local/sbin/archive-source-backup
/etc/systemd/system/archive-source-backup.service
/etc/systemd/system/archive-source-backup.timer

# us
/usr/local/sbin/archive-destination
/usr/local/sbin/archive-restore
/etc/systemd/system/archive-destination.service
/etc/systemd/system/archive-destination.timer
```

`us1` 每小时第 5 分钟执行：

```text
archive-source-backup.timer
```

`us` 每小时第 15 分钟执行：

```text
archive-destination.timer
```

查看状态：

```bash
systemctl list-timers 'archive-*'
journalctl -u archive-source-backup.service
journalctl -u archive-destination.service
```

手动执行：

```bash
# us1
systemctl start archive-source-backup.service

# us
systemctl start archive-destination.service
```

## 5. 失败处理

- 导出失败：不生成备份文件。
- 打包失败：不上传文件。
- 上传失败：压缩包保留在 `us1` 的 `/etc/archive/spool`，下次继续上传。
- 校验失败：文件留在 `us` 的 `incoming`，不会进入正式归档。
- 新备份成功前不会清理已有备份。

## 6. 恢复

先重新部署 Sub2API 环境并创建空数据库，再停止应用：

```bash
systemctl stop sub2api
```

将指定的 `.tar.gz`、`.sha256` 和 `archive-restore` 复制到重建后的数据库服务器，再执行：

```bash
CONFIRM_RESTORE=1 /usr/local/sbin/archive-restore \
  /path/to/YYYYMMDD-HHMMSS-xxxxxxxx.tar.gz
```

恢复完成后启动应用：

```bash
systemctl start sub2api
```
