#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="${SCRIPT_DIR}"

DEFAULT_SERVICES=(
  postgres
  redis
  rigel-jd-collector
  rigel-build-engine
  rigel-console
)

usage() {
  cat <<'EOF'
Usage:
  ./rigel.sh up [service...]
  ./rigel.sh start [service...]
  ./rigel.sh down
  ./rigel.sh restart [service...]
  ./rigel.sh logs [service...]
  ./rigel.sh ps
  ./rigel.sh build [service...]
  ./rigel.sh console-ui

Default services:
  postgres redis rigel-jd-collector rigel-build-engine rigel-console
EOF
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

require_tool docker

if [[ ! -f "${CORE_DIR}/docker-compose.yml" ]]; then
  echo "docker-compose.yml not found under ${CORE_DIR}" >&2
  exit 1
fi

if [[ ! -f "${CORE_DIR}/.env" ]]; then
  echo ".env not found under ${CORE_DIR}" >&2
  echo "copy .env.example to .env first" >&2
  exit 1
fi

compose() {
  docker compose -f "${CORE_DIR}/docker-compose.yml" --env-file "${CORE_DIR}/.env" "$@"
}

refresh_console_ui() {
  local console_dir="${CORE_DIR}/../rigel-console"
  local frontend_dir="${console_dir}/frontend"

  require_tool npm

  if [[ ! -d "${frontend_dir}" ]]; then
    echo "frontend directory not found: ${frontend_dir}" >&2
    exit 1
  fi

  if [[ -f "${frontend_dir}/package-lock.json" ]]; then
    if [[ ! -d "${frontend_dir}/node_modules" ]]; then
      echo "frontend dependencies missing, running npm ci..."
      (cd "${frontend_dir}" && npm ci)
    fi
  elif [[ ! -d "${frontend_dir}/node_modules" ]]; then
    echo "frontend dependencies missing, running npm install..."
    (cd "${frontend_dir}" && npm install)
  fi

  echo "building rigel-console frontend..."
  (cd "${frontend_dir}" && npm run build)

  echo "restarting rigel-console service..."
  compose up -d --build rigel-console
}

command_name="${1:-up}"
if [[ $# -gt 0 ]]; then
  shift
fi

if [[ $# -gt 0 ]]; then
  services=("$@")
else
  services=("${DEFAULT_SERVICES[@]}")
fi

case "${command_name}" in
  up)
    compose up -d --build "${services[@]}"
    ;;
  start)
    compose up -d "${services[@]}"
    ;;
  down)
    compose down
    ;;
  restart)
    compose up -d --build "${services[@]}"
    ;;
  logs)
    compose logs -f "${services[@]}"
    ;;
  ps)
    compose ps
    ;;
  build)
    compose build "${services[@]}"
    ;;
  console-ui)
    refresh_console_ui
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "unknown command: ${command_name}" >&2
    usage >&2
    exit 1
    ;;
esac
