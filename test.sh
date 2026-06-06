#!/bin/bash

set -e

image="$1"
if [ -z "$image" ]; then
  echo "Usage: ./test.sh <image>"
  exit
fi

if ! docker image inspect -f "{{.Config.Entrypoint}}{{.Config.Cmd}}" $image | grep -q 'php-fpm'; then
  echo "Not php-fpm !"
  exit
fi

if ! command -v cgi-fcgi > /dev/null; then
  sudo apt-get update && sudo apt-get install -y libfcgi0ldbl
fi

INDEX_FILE="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/index.php"

# 启动容器（不挂载 index.php，避免 CI 中宿主路径不匹配）
docker run -d --rm -p 9000:9000 --name test-php-fpm $image
trap 'docker stop test-php-fpm >/dev/null 2>&1 || true' EXIT

# 容器启动后用 docker cp 拷贝文件（不依赖宿主机路径，CI 和本地均可用）
docker cp "$INDEX_FILE" test-php-fpm:/var/www/html/index.php
sleep 1

export SCRIPT_NAME=/index.php
export SCRIPT_FILENAME=/var/www/html/index.php
export REQUEST_METHOD=GET

# 获取容器 IP 优先连接（CI 容器内可通过此 IP 访问 PHP-FPM）
FPM_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test-php-fpm)
echo "PHP-FPM IP: $FPM_IP"

if [ -z "$FPM_IP" ] || ! cgi-fcgi -bind -connect "${FPM_IP}:9000"; then
  echo "try local"
  cgi-fcgi -bind -connect "127.0.0.1:9000"
fi
