#!/bin/bash
export https_proxy=http://127.0.0.1:38458

echo "Cleaning up old containers..."
# Use || true to prevent exit on error if no containers found
ids=$(sudo docker ps -a -q --filter name=tradingagents)
if [ -n "$ids" ]; then
    sudo docker rm -f $ids || true
fi

echo "Cleaning up old images..."
image_ids=$(sudo docker images | grep 'tradingagents' | awk '{print $3}')
if [ -n "$image_ids" ]; then
    sudo docker rmi -f $image_ids || true
fi

echo "Cleaning up directories..."
rm -rf TradingAgentsCN_V1
# Remove repo.zip only if we are starting fresh, but here we want to allow resume if possible
# However, user said "delete all", so we start clean to avoid corrupt resume.
rm -f repo.zip

echo "Downloading new version..."
URL="https://github.com/skyarcher2008/TradingAgentsCN_V1/archive/refs/heads/main.zip"
MAX_RETRIES=10
COUNT=0
SUCCESS=0

while [ $COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $(($COUNT + 1)) of $MAX_RETRIES..."
    
    # Explained options:
    # -L: Follow redirects
    # -k: Skip SSL verification (good for proxies)
    # --http1.1: Force HTTP/1.1 to avoid HTTP/2 stream errors
    # -C -: Continue/Resume download if partially downloaded
    # --retry 3: Curl's internal retry mechanism for transient errors
    # --retry-delay 5: Wait between internal retries
    # --connect-timeout 120: Allow 2 mins to establish connection
    # --speed-time 30 --speed-limit 1000: If speed drops below 1KB/s for 30s, considering it stalled
    
    curl -L -k --http1.1 -C - --retry 3 --retry-delay 5 --connect-timeout 120 --keepalive-time 60 -o repo.zip "$URL"
    
    RUN_STATUS=$?
    
    if [ $RUN_STATUS -eq 0 ]; then
        # Check if file is a valid zip using unzip test
        # Note: BusyBox unzip might support -t
        if unzip -tq repo.zip >/dev/null 2>&1; then
            echo "Download successful and verified."
            SUCCESS=1
            break
        else
            echo "Downloaded file is corrupt (unzip check failed). Redownloading..."
            rm -f repo.zip
        fi
    else
        echo "Curl failed with exit code $RUN_STATUS."
    fi
    
    COUNT=$(($COUNT + 1))
    echo "Waiting 15s before next attempt..."
    sleep 15
done

if [ $SUCCESS -eq 0 ]; then
    echo "Failed to download after $MAX_RETRIES attempts."
    exit 1
fi

echo "Unzipping..."
unzip -q -o repo.zip
mv TradingAgentsCN_V1-main TradingAgentsCN_V1
cd TradingAgentsCN_V1

echo "Applying fixes for NAS/BusyBox..."
# Allow failing if files don't exist
rm -f docs/analysis/*20251011.md || true
rm -f docs/paper/*.md || true
rm -f docs/technical/DeepSeek+*.md || true
rm -f scripts/[!a-zA-Z]* || true
sed -i '/TradingAgents_论文中文版/d' frontend/src/views/Learning/Article.vue || true

echo "Applying port fixes (avoiding 27017/6379/6380 conflicts)..."
sed -i 's/"27017:27017"/"27019:27017"/g' docker-compose.yml
sed -i 's/"6379:6379"/"16379:6379"/g' docker-compose.yml

echo "Starting build..."
cp .env.docker .env
sudo docker compose up -d --build
