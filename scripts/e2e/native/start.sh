#!/usr/bin/env bash
# Runs the e2e HumHub backend natively: PHP's built-in server and MariaDB on
# the host. Used for iOS (see ../lib.sh). Safe to re-run.
#
# HumHub itself is copied out of the same humhub/humhub image the Docker
# backend uses (no Docker needed), so both platforms test the same build.
#
# Requires: php 8.2+ (exif, intl, zip, pdo_mysql, gd, mbstring, curl),
# mariadb, crane.
#
# Env:
#   HUMHUB_IMAGE_TAG  humhub/humhub image tag (default: 1.18, like docker-compose.yml)
#   E2E_PORT          port to serve on (default: 8080)
set -euo pipefail

native_dir="$(cd "$(dirname "$0")" && pwd)"
e2e_dir="$(dirname "$native_dir")"
humhub_dir="$native_dir/.humhub"
cache_dir="$native_dir/.cache"
logs_dir="$e2e_dir/logs/humhub"
image="humhub/humhub:${HUMHUB_IMAGE_TAG:-1.18}"
image_tar="$cache_dir/humhub-${HUMHUB_IMAGE_TAG:-1.18}.tar"
port="${E2E_PORT:-8080}"
server_pid_file="$native_dir/.server.pid"

mkdir -p "$cache_dir" "$logs_dir"

# Pristine copy of /opt/humhub, kept (and cached in CI) so a fresh install
# never sees the state of a previous one.
if [ ! -f "$image_tar" ]; then
  echo "Copying /opt/humhub out of $image..."
  tmp="$(mktemp -d)"
  crane export --platform linux/amd64 "$image" - | tar -x -f - -C "$tmp" opt/humhub
  tar -c -f "$image_tar" -C "$tmp/opt" humhub
  rm -rf "$tmp"
fi

if [ ! -f "$humhub_dir/protected/yii" ]; then
  echo "Extracting HumHub..."
  mkdir -p "$humhub_dir"
  tar -x -f "$image_tar" -C "$humhub_dir" --strip-components 1
  mkdir -p "$humhub_dir/assets" "$humhub_dir/uploads" "$humhub_dir/protected/runtime" "$humhub_dir/protected/modules"
  # The test fixtures module, like the volume in docker-compose.yml.
  ln -sfn "$e2e_dir/seed_module" "$humhub_dir/protected/modules/e2e"
fi

# Same settings as the Docker image and docker-compose.yml; HumHub reads them
# from .env for both the web app and the console.
cat > "$humhub_dir/.env" <<'EOF'
HUMHUB_DEBUG=true
HUMHUB_CONFIG__COMPONENTS__DB__DSN="mysql:host=127.0.0.1;port=3306;dbname=humhub"
HUMHUB_CONFIG__COMPONENTS__DB__USERNAME=humhub
HUMHUB_CONFIG__COMPONENTS__DB__PASSWORD=e2e
HUMHUB_CONFIG__COMPONENTS__URL_MANAGER__SHOW_SCRIPT_NAME=false
HUMHUB_CONFIG__COMPONENTS__URL_MANAGER__ENABLE_PRETTY_URL=true
HUMHUB_CLI_CONFIG__CONTROLLER_MAP__INSTALLER='humhub\modules\installer\commands\InstallController'
EOF

if ! mariadb-admin ping > /dev/null 2>&1; then
  echo "Starting MariaDB..."
  brew services start mariadb > /dev/null
  for _ in $(seq 60); do
    mariadb-admin ping > /dev/null 2>&1 && break
    sleep 1
  done
fi
# Per local host, not '%': Homebrew's MariaDB has anonymous ''@'localhost'
# accounts, which would match before 'humhub'@'%' and deny the login.
mariadb <<'EOF'
CREATE DATABASE IF NOT EXISTS humhub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'humhub'@'localhost' IDENTIFIED BY 'e2e';
CREATE USER IF NOT EXISTS 'humhub'@'127.0.0.1' IDENTIFIED BY 'e2e';
GRANT ALL PRIVILEGES ON humhub.* TO 'humhub'@'localhost';
GRANT ALL PRIVILEGES ON humhub.* TO 'humhub'@'127.0.0.1';
EOF

if [ -f "$server_pid_file" ] && kill -0 "$(cat "$server_pid_file")" 2> /dev/null; then
  echo "HumHub server already running."
else
  echo "Starting HumHub on http://127.0.0.1:$port..."
  # Several workers, as the WebView loads assets in parallel.
  PHP_CLI_SERVER_WORKERS=4 nohup php \
    -d memory_limit=512M -d post_max_size=64M -d upload_max_filesize=64M \
    -S "127.0.0.1:$port" -t "$humhub_dir" "$native_dir/router.php" \
    > "$logs_dir/server.log" 2>&1 &
  echo $! > "$server_pid_file"
fi

for _ in $(seq 60); do
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/" || true)"
  if [ "$code" != "000" ]; then
    exit 0
  fi
  sleep 1
done
echo "HumHub did not respond on port $port, see $logs_dir/server.log" >&2
exit 1
