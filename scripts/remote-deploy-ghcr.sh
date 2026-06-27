#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="${1:-/mnt/sdb/xianyu-auto-reply}"
IMAGE_TAG="${2:?IMAGE_TAG is required}"

cd "$DEPLOY_DIR"

if [ ! -f docker-compose.yml ]; then
  echo "docker-compose.yml not found in $DEPLOY_DIR" >&2
  exit 1
fi

if [ ! -f .env ]; then
  if [ ! -f production.env.example ]; then
    echo "production.env.example not found in $DEPLOY_DIR" >&2
    exit 1
  fi

  cp production.env.example .env
  chmod 600 .env

  rand_secret() {
    openssl rand -base64 32 | tr -d '\n' | sed 's/[\/&]/_/g'
  }

  set_env_value() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" .env; then
      sed -i "s|^${key}=.*|${key}=${value}|" .env
    else
      printf '%s=%s\n' "$key" "$value" >> .env
    fi
  }

  set_env_value MYSQL_ROOT_PASSWORD "$(rand_secret)"
  set_env_value MYSQL_PASSWORD "$(rand_secret)"
  set_env_value REDIS_PASSWORD "$(rand_secret)"
  set_env_value EXTERNAL_API_KEY "$(rand_secret)"
fi

set_env_value() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf '%s=%s\n' "$key" "$value" >> .env
  fi
}

set_env_value IMAGE_TAG "$IMAGE_TAG"

mkdir -p \
  data/mysql \
  data/redis \
  data/logs/backend_web \
  data/logs/websocket \
  data/logs/scheduler \
  data/static \
  data/backups \
  data/browser_data

docker compose --env-file .env -f docker-compose.yml pull
docker compose --env-file .env -f docker-compose.yml up -d --remove-orphans
docker image prune -f --filter dangling=true

docker compose --env-file .env -f docker-compose.yml ps
