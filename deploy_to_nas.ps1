# TradingAgents NAS 部署脚本
# 自动连接 NAS，拉取 Github 代码并启动 Docker
# 预设环境：BusyBox NAS, N150 CPU

$NAS_USER = "skyarcher"
$NAS_IP = "192.168.68.100"
$NAS_PORT = "10000"
# 使用 HTTPS 地址以避免 NAS 上的 SSH Key 配置问题
$REPO_URL = "https://github.com/skyarcher2008/TradingAgentsCN_V1.git"

Write-Host "🚀 正在连接 NAS ($NAS_IP) 开始部署..." -ForegroundColor Green

# 远程执行的 Shell 脚本内容
$RemoteScript = @"
set -e # 遇到错误立即停止

echo "🔧 [1/5] 配置网络代理 (利用 FastGitHub 127.0.0.1:38457)..."
export http_proxy=http://127.0.0.1:38457
export https_proxy=http://127.0.0.1:38457
# 设置 pip 镜像环境变量 (Dockerfile 中也会用到)
export PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/

echo "📂 [2/5] 准备部署目录..."
mkdir -p ~/projects/TradingAgentsCN_V1
cd ~/projects/TradingAgentsCN_V1

echo "dw [3/5] 同步代码..."
if [ -d ".git" ]; then
    echo "   更新现有代码..."
    git pull
else
    echo "   克隆新代码..."
    git clone "$REPO_URL" .
fi

echo "⚙️ [4/5] 配置环境变量..."
if [ ! -f ".env" ]; then
    echo "   从 .env.docker 创建 .env..."
    cp .env.docker .env
else
    # 确保 .env 存在，如果需要更新配置可以在这里添加逻辑
    echo "   保留现有 .env 配置"
fi

echo "🐳 [5/5] 启动容器 (N150 构建较慢，请耐心等待)..."
# 停止旧容器
sudo docker compose down --remove-orphans || true

# 启动新容器 (强制构建以应用可能的新依赖)
# 传递代理变量给构建过程 (如果 Dockerfile 支持 ARG http_proxy)
sudo docker compose up -d --build

echo "✅ 部署完成！服务状态："
sudo docker compose ps
"@

# 执行 SSH 命名
# 注意：这会请求输入 NAS 密码，或者使用已配置的 SSH Key
ssh -p $NAS_PORT $NAS_USER@$NAS_IP $RemoteScript
