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
REPO_GIT="https://github.com/skyarcher2008/TradingAgentsCN_V1.git"
REPO_TARBALL="https://codeload.github.com/skyarcher2008/TradingAgentsCN_V1/tar.gz/refs/heads/main"

download_file() {
    url="$1"
    out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -L --fail -o "$out" "$url"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -O "$out" "$url"
        return $?
    fi
    echo "❌ 缺少 curl/wget，无法下载代码"
    return 1
}

copy_tree() {
    src="$1"
    dst="$2"
    if cp -a "$src/." "$dst" 2>/dev/null; then
        return 0
    fi
    cp -R "$src/." "$dst"
}

if command -v git >/dev/null 2>&1; then
    if [ -d ".git" ]; then
        echo "   使用 git 更新现有代码..."
        git fetch --all --prune
        git reset --hard origin/main
    else
        echo "   使用 git 克隆新代码..."
        git clone "$REPO_GIT" .
    fi
else
    echo "   未安装 git，改用下载源码包方式部署..."
    tmpdir="/tmp/tradingagents_deploy_$$"
    rm -rf "$tmpdir" >/dev/null 2>&1 || true
    mkdir -p "$tmpdir/extract"

    archive="$tmpdir/repo.tar.gz"
    echo "   下载: $REPO_TARBALL"
    download_file "$REPO_TARBALL" "$archive"

    # 解压
    tar -xzf "$archive" -C "$tmpdir/extract"
    rootdir="$(ls -1 "$tmpdir/extract" 2>/dev/null | head -n 1)"
    if [ -z "$rootdir" ] || [ ! -d "$tmpdir/extract/$rootdir" ]; then
        echo "❌ 解压失败，未找到源码目录"
        exit 1
    fi

    # 保护本地持久化内容
    mkdir -p "$tmpdir/preserve"
    for p in .env data logs; do
        if [ -e "$p" ]; then
            mv "$p" "$tmpdir/preserve/" 2>/dev/null || true
        fi
    done

    # 清空目录（避免覆盖旧文件）
    find . -mindepth 1 -maxdepth 1 -exec rm -rf {} +

    # 拷贝新代码
    copy_tree "$tmpdir/extract/$rootdir" .

    # 还原持久化内容
    for p in .env data logs; do
        if [ -e "$tmpdir/preserve/$p" ]; then
            rm -rf "$p" 2>/dev/null || true
            mv "$tmpdir/preserve/$p" "$p" 2>/dev/null || true
        fi
    done

    rm -rf "$tmpdir" >/dev/null 2>&1 || true
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

ensure_image() {
    target="$1"  # e.g. python:3.10-slim-bookworm
    shift

    if $SUDO docker image inspect "$target" >/dev/null 2>&1; then
        echo "   ✅ 已存在: $target"
        return 0
    fi

    echo "   ⬇️  预拉取基础镜像: $target"

    # Try direct pull first (may fail if registry mirror is down)
    if $SUDO docker pull "$target" >/dev/null 2>&1; then
        echo "   ✅ 拉取成功: $target"
        return 0
    fi

    for candidate in "$@"; do
        echo "   尝试镜像源: $candidate"
        if $SUDO docker pull "$candidate"; then
            $SUDO docker tag "$candidate" "$target"
            echo "   ✅ 使用镜像源成功，并已标记为: $target"
            return 0
        fi
    done

    echo "❌ 无法拉取基础镜像: $target"
    return 1
}

echo "🧱 [5a] 预拉取基础镜像(避免 DockerHub 超时)..."
# Backend base image
ensure_image "python:3.10-slim-bookworm" \
    "docker.m.daocloud.io/library/python:3.10-slim-bookworm" \
    "mirror.ccs.tencentyun.com/library/python:3.10-slim-bookworm" || exit 1

# Frontend build/runtime base images
ensure_image "node:22-alpine" \
    "docker.m.daocloud.io/library/node:22-alpine" \
    "mirror.ccs.tencentyun.com/library/node:22-alpine" || exit 1

ensure_image "nginx:alpine" \
    "docker.m.daocloud.io/library/nginx:alpine" \
    "mirror.ccs.tencentyun.com/library/nginx:alpine" || exit 1

$SUDO $DC down --remove-orphans || true
$SUDO $DC up -d --build

echo "✅ 部署完成！服务状态："
$SUDO $DC ps
