#!/bin/bash

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

echo "[Trivy 漏洞扫描]"
TRIVY_IMAGE="aquasec/trivy"
TRIVY_CACHE="$HOME/trivy-cache"
DOCKER_IMAGE="moremay/php:8"

# 实时输出trivy结果并统计漏洞数
TRIVY_OUTPUT_FILE="trivy_output.tmp"
eval "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $TRIVY_CACHE:/root/.cache/ $TRIVY_IMAGE image $DOCKER_IMAGE" | tee "$TRIVY_OUTPUT_FILE"
VUL_COUNT=$(grep -E 'Total:|CRITICAL|HIGH|MEDIUM|LOW' "$TRIVY_OUTPUT_FILE" | grep -v 'None' | wc -l)
rm -f "$TRIVY_OUTPUT_FILE"
echo "$DOCKER_IMAGE 漏洞数: $VUL_COUNT"

# 2. 检查github上的php是否有新版本
# 获取当前版本
LATEST_DIR=""
CURRENT_VERSION=""
for dir in 8.*; do
    if [ -d "$dir" ] && [ -f "$dir/.latest" ]; then
        LATEST_DIR="$dir"
        CURRENT_VERSION=$(grep 'PHP_VERSION=' "$dir/Dockerfile" | head -1 | sed -E 's/.*PHP_VERSION=([0-9.]+).*/\1/')
        break
    fi
done

echo ""
echo "[获取 PHP 最新版本]"
GITHUB_TAG=$(curl -s https://api.github.com/repos/php/php-src/releases | grep 'tag_name' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
# 提取版本号（去除前缀如php-）
GITHUB_VERSION=$(echo "$GITHUB_TAG" | sed -E 's/^php-([0-9.]+)$/\1/')
echo "PHP 版本: $CURRENT_VERSION"
echo "GitHub PHP 最新版本: $GITHUB_VERSION"

# log字段处理
PHP_LOG=""
if [ "$CURRENT_VERSION" != "$GITHUB_VERSION" ] && [ "$GITHUB_VERSION" != "" ]; then
    PHP_LOG="$GITHUB_VERSION"
fi

LOG_FILE="check-versions.log"
echo "vul=$VUL_COUNT" > "$LOG_FILE"
echo "php=$PHP_LOG" >> "$LOG_FILE"

echo ""
echo "[结论]"
if [ $VUL_COUNT -ne 0 ] || [ -n "$PHP_LOG" ]; then
    echo "RESULT: yes"
else
    echo "RESULT: no"
fi

exit 0
