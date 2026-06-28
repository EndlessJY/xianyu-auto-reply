#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="${1:-/mnt/sdb/xianyu-auto-reply}"
IMAGE_TAG="${2:?IMAGE_TAG is required}"
SERVICES_CSV="${3:-backend-web,websocket,scheduler,frontend}"

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
      local tmp_file
      tmp_file="$(mktemp)"
      awk -v key="$key" -v value="$value" '
        BEGIN { prefix = key "=" }
        index($0, prefix) == 1 { $0 = prefix value }
        { print }
      ' .env > "$tmp_file"
      mv "$tmp_file" .env
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
    local tmp_file
    tmp_file="$(mktemp)"
    awk -v key="$key" -v value="$value" '
      BEGIN { prefix = key "=" }
      index($0, prefix) == 1 { $0 = prefix value }
      { print }
    ' .env > "$tmp_file"
    mv "$tmp_file" .env
  else
    printf '%s=%s\n' "$key" "$value" >> .env
  fi
}

existing_image_tag="$(grep -E '^IMAGE_TAG=' .env | tail -n 1 | cut -d= -f2- || true)"
existing_image_tag="${existing_image_tag:-latest}"

set_env_value IMAGE_TAG "$IMAGE_TAG"

for key in BACKEND_WEB_IMAGE_TAG WEBSOCKET_IMAGE_TAG SCHEDULER_IMAGE_TAG FRONTEND_IMAGE_TAG; do
  if ! grep -q "^${key}=" .env; then
    set_env_value "$key" "$existing_image_tag"
  fi
done

service_tag_key() {
  case "$1" in
    backend-web) echo "BACKEND_WEB_IMAGE_TAG" ;;
    websocket) echo "WEBSOCKET_IMAGE_TAG" ;;
    scheduler) echo "SCHEDULER_IMAGE_TAG" ;;
    frontend) echo "FRONTEND_IMAGE_TAG" ;;
    *)
      echo "Unknown service: $1" >&2
      exit 1
      ;;
  esac
}

IFS=',' read -r -a services <<< "$SERVICES_CSV"
deploy_services=()
for service in "${services[@]}"; do
  service="$(echo "$service" | xargs)"
  [ -n "$service" ] || continue
  deploy_services+=("$service")
  set_env_value "$(service_tag_key "$service")" "$IMAGE_TAG"
done

if [ "${#deploy_services[@]}" -eq 0 ]; then
  echo "No services requested for deployment" >&2
  exit 1
fi

mkdir -p \
  data/mysql \
  data/redis \
  data/logs/backend_web \
  data/logs/websocket \
  data/logs/scheduler \
  data/static \
  data/backups \
  data/browser_data

docker compose --env-file .env -f docker-compose.yml pull "${deploy_services[@]}"
docker compose --env-file .env -f docker-compose.yml up -d --remove-orphans
docker image prune -f --filter dangling=true

docker compose --env-file .env -f docker-compose.yml ps
