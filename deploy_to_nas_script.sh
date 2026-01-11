set -e

echo "🔧 [1/5] 配置网络代理(可选)..."
PROXY_URL="http://127.0.0.1:38457"
PROXY_OK=0
if command -v curl >/dev/null 2>&1; then
    if curl -s --max-time 2 "$PROXY_URL" >/dev/null 2>&1; then
        PROXY_OK=1
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q -T 2 -O /dev/null "$PROXY_URL" >/dev/null 2>&1; then
        PROXY_OK=1
    fi
fi

if [ "$PROXY_OK" -eq 1 ]; then
    echo "   发现本地代理: $PROXY_URL，已启用 http(s)_proxy"
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
else
    echo "   未检测到本地代理，跳过代理配置"
fi

# pip 镜像(可选)
export PIP_INDEX_URL="https://mirrors.aliyun.com/pypi/simple/"

echo "📂 [2/5] 准备部署目录..."
mkdir -p ~/projects/TradingAgentsCN_V1
cd ~/projects/TradingAgentsCN_V1

echo "🔄 [3/5] 同步代码..."
if [ -d ".git" ]; then
    echo "   更新现有代码..."
    git fetch --all --prune
    git reset --hard origin/main
else
    echo "   克隆新代码..."
    # 注意：这里使用固定地址，避免参数传递复杂度
    git clone "https://github.com/skyarcher2008/TradingAgentsCN_V1.git" .
fi

echo "⚙️ [4/5] 配置环境变量..."
if [ ! -f ".env" ]; then
    echo "   从 .env.docker 创建 .env..."
    cp .env.docker .env
else
    echo "   保留现有 .env 配置"
fi

echo "🐳 [5/5] 启动容器 (N150 构建较慢，请耐心等待)..."
DC=""
if docker compose version >/dev/null 2>&1; then
    DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DC="docker-compose"
else
    echo "❌ 未找到 docker compose / docker-compose"
    exit 1
fi

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

$SUDO $DC down --remove-orphans || true
$SUDO $DC up -d --build

echo "✅ 部署完成！服务状态："
$SUDO $DC ps
