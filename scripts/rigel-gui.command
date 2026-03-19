#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLI_SCRIPT="${SCRIPT_DIR}/rigel.sh"

SERVICES=(
  postgres
  redis
  rigel-jd-collector
  rigel-build-engine
  rigel-console
)

ACTION_HINT=$'可用动作:\nup\nstart\nrestart\nbuild\nlogs\nps\ndown'
SERVICE_HINT=$'可用服务:\npostgres\nredis\nrigel-jd-collector\nrigel-build-engine\nrigel-console\n\n多个服务用英文逗号分隔。'

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    osascript -e "display alert \"Missing Command\" message \"Required command not found: $1\" as critical"
    exit 1
  fi
}

require_tool osascript

if [[ ! -x "${CLI_SCRIPT}" ]]; then
  osascript -e "display alert \"Missing Script\" message \"${CLI_SCRIPT} is not executable\" as critical"
  exit 1
fi

show_error() {
  osascript -e "display alert \"Rigel GUI\" message \"$1\" as critical"
}

prompt_value() {
  local prompt_message="$1"
  local default_answer="$2"

  PROMPT_MESSAGE="${prompt_message}" DEFAULT_ANSWER="${default_answer}" osascript <<'APPLESCRIPT'
set promptMessage to system attribute "PROMPT_MESSAGE"
set defaultAnswer to system attribute "DEFAULT_ANSWER"
set resultRecord to display dialog promptMessage default answer defaultAnswer buttons {"取消", "确定"} default button "确定"
return text returned of resultRecord
APPLESCRIPT
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

action="$(prompt_value "${ACTION_HINT}" "up" || true)"
action="$(trim "${action}")"

case "${action}" in
  up|start|restart|build|logs|ps|down)
    ;;
  "")
    exit 0
    ;;
  *)
    show_error "无效动作: ${action}"
    exit 1
    ;;
esac

services=()
case "${action}" in
  up|start|restart|build)
    picked="$(prompt_value "${SERVICE_HINT}" "postgres,redis,rigel-jd-collector,rigel-build-engine,rigel-console" || true)"
    [[ -z "${picked}" ]] && exit 0
    IFS=',' read -r -a raw_services <<< "${picked}"
    for raw_service in "${raw_services[@]}"; do
      service="$(trim "${raw_service}")"
      [[ -n "${service}" ]] && services+=("${service}")
    done
    ;;
  logs)
    picked="$(prompt_value "${SERVICE_HINT}" "rigel-console" || true)"
    [[ -z "${picked}" ]] && exit 0
    IFS=',' read -r -a raw_services <<< "${picked}"
    for raw_service in "${raw_services[@]}"; do
      service="$(trim "${raw_service}")"
      [[ -n "${service}" ]] && services+=("${service}")
    done
    ;;
  ps|down)
    ;;
esac

if [[ "${#services[@]}" -gt 0 ]]; then
  valid_services=(" ${SERVICES[*]} ")
  for service in "${services[@]}"; do
    if [[ ! " ${SERVICES[*]} " =~ [[:space:]]${service}[[:space:]] ]]; then
      show_error "无效服务: ${service}"
      exit 1
    fi
  done
fi

command_parts=("${CLI_SCRIPT}" "${action}")
if [[ "${#services[@]}" -gt 0 ]]; then
  command_parts+=("${services[@]}")
fi

command_string="cd ${CORE_DIR} &&"
for part in "${command_parts[@]}"; do
  command_string+=" $(printf '%q' "${part}")"
done

osascript <<APPLESCRIPT
tell application "Terminal"
	activate
	do script $(printf '%q' "${command_string}")
end tell
APPLESCRIPT
