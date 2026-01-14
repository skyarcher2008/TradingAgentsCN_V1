# Docker 服务停止/启动帮助文档（TradingAgentsCN_V1）

本文档用于指导你在 NAS / Linux / Windows 环境中，**停止、启动、重启、查看状态、查看日志、清理数据**，以及在常见故障（比如 MongoDB 初始化变慢）时如何处理。

> 适用范围
> - 本项目使用 `docker compose`（或兼容的 `docker-compose`）管理服务。
> - 默认服务包含：`backend`、`frontend`、`mongodb`、`redis`（以及可选的 `redis-commander`）。

---

## 1. 基本概念（先看这个）

- **容器（container）**：运行中的服务实例，例如 `tradingagents-backend`。
- **镜像（image）**：构建容器的“模板”，例如 `tradingagents-backend:v1.0.0-preview`。
- **数据卷（volume）**：持久化数据库/缓存的数据（删除容器不会自动删除卷）。例如 MongoDB、Redis 的数据卷。
- **Compose 项目目录**：包含 `docker-compose.yml` 的目录。在 NAS 上通常是 `~/projects/TradingAgentsCN_V1`。

关键点：
- `docker compose down` 会停掉并删除容器/网络，但**默认不会删数据卷**。
- 要“从零开始”，需要额外删除 volumes。

---

## 2. 在 NAS 上管理服务（推荐方式）

### 2.1 登录 NAS（SSH）

你的 NAS 配置是：SSH 端口 `10000`。

- Windows PowerShell：
  - `ssh -p 10000 skyarcher@192.168.68.100`

登录后进入项目目录：
- `cd ~/projects/TradingAgentsCN_V1`

---

## 3. 查看状态与健康情况

### 3.1 查看 compose 服务状态

在项目目录执行：
- `sudo docker compose ps`

你会看到类似：
- `Up ... (healthy)`：健康
- `Up ... (unhealthy)`：健康检查失败
- `Created` / `Exited`：未正常运行

### 3.2 查看所有容器（含非本项目）

- `sudo docker ps -a`

### 3.3 查看日志（排错最常用）

- 查看某个容器最新日志：
  - `sudo docker logs --tail 200 tradingagents-backend`
  - `sudo docker logs --tail 200 tradingagents-mongodb`

- 持续跟踪日志（实时刷新）：
  - `sudo docker logs -f tradingagents-backend`

---

## 4. 启动 / 停止 / 重启（常用命令）

### 4.1 启动（第一次/更新后）

在项目目录执行：
- `sudo docker compose up -d`

如果你更新了代码/依赖，需要重新构建镜像：
- `sudo docker compose up -d --build`

### 4.2 停止但保留容器（可快速恢复）

- `sudo docker compose stop`

再次启动：
- `sudo docker compose start`

### 4.3 重启

- 重启全部服务：
  - `sudo docker compose restart`

- 只重启某个服务（例如后端）：
  - `sudo docker compose restart backend`

### 4.4 停止并删除容器（推荐的“标准停止”）

在项目目录执行：
- `sudo docker compose down --remove-orphans`

说明：
- 会删除容器与网络
- **不会删除数据卷**（Mongo/Redis 数据仍在）

---

## 5. 从零开始（彻底清空数据）

如果你想完全清空数据库/缓存数据（不可恢复），使用：

- `sudo docker compose down --volumes --remove-orphans`

再配合（可选）清理无用镜像/缓存：
- `sudo docker system prune -f`

如果你还想把本项目构建出来的镜像也删掉：
- `sudo docker image rm -f tradingagents-backend:v1.0.0-preview tradingagents-frontend:v1.0.0-preview || true`

---

## 6. 常见问题与处理

### 6.1 `dependency failed to start: ... mongodb is unhealthy`

原因通常是：
- **首次启动 MongoDB 会初始化（建库/建用户/初始化脚本），需要时间**

处理建议：
1. 先看 Mongo 日志：
   - `sudo docker logs --tail 200 tradingagents-mongodb`
2. 等待 1~3 分钟再看状态：
   - `sudo docker compose ps`
3. 若 Mongo 已变成 healthy，但后端/前端没起来：
   - `sudo docker compose up -d --build backend frontend`

### 6.2 `Permission denied` 删除不了 data/logs

原因：
- 容器内产生的文件可能属于 `root`，普通用户无法直接删除。

解决方案（推荐）：
- 使用一个临时 Alpine 容器代删（强制清理目录）：
  - `sudo docker run --rm -v /home/skyarcher/projects:/data alpine rm -rf /data/TradingAgentsCN_V1`

### 6.3 Docker 拉基础镜像超时（比如 `python:3.10-slim-bookworm`）

表现：
- 构建阶段卡在 `load metadata` 或 `i/o timeout`

处理建议：
1. 先尝试预拉取（可改用镜像源/加速器）：
   - `sudo docker pull docker.m.daocloud.io/library/python:3.10-slim-bookworm`
   - `sudo docker tag docker.m.daocloud.io/library/python:3.10-slim-bookworm python:3.10-slim-bookworm`
2. 再执行：
   - `sudo docker compose up -d --build`

---

## 7. 在 Windows 本机一键操作（通过 SSH 远程执行）

如果你不想手动登录 NAS，可以在 Windows PowerShell 里用一条命令执行远程操作。

- 查看 NAS 上的服务状态：
  - `ssh -p 10000 skyarcher@192.168.68.100 "cd ~/projects/TradingAgentsCN_V1 && sudo docker compose ps"`

- 停止并删除容器（保留数据卷）：
  - `ssh -p 10000 skyarcher@192.168.68.100 "cd ~/projects/TradingAgentsCN_V1 && sudo docker compose down --remove-orphans"`

- 从零开始（删除容器 + 删除数据卷）：
  - `ssh -p 10000 skyarcher@192.168.68.100 "cd ~/projects/TradingAgentsCN_V1 && sudo docker compose down --volumes --remove-orphans"`

---

## 8. 推荐的日常运维流程（最省事）

- 日常重启：`sudo docker compose restart`
- 更新代码后：`sudo docker compose up -d --build`
- 只看状态：`sudo docker compose ps`
- 出问题先看：`sudo docker logs --tail 200 tradingagents-backend`（或 mongodb/redis）

---

如需我把这些命令也整合进一个 `nas_manage.ps1`（菜单式：1 启动/2 停止/3 重启/4 清空），我也可以直接帮你加到仓库里。