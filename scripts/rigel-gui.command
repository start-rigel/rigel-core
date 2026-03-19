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

join_lines() {
  local IFS=$'\n'
  printf '%s' "$*"
}

pick_action() {
  osascript <<'APPLESCRIPT'
set actionList to {"up", "start", "restart", "build", "logs", "ps", "down"}
set chosenAction to choose from list actionList with prompt "选择 Rigel 操作" default items {"up"} OK button name "继续" cancel button name "取消" without multiple selections allowed and empty selection allowed false
if chosenAction is false then
	return ""
end if
return item 1 of chosenAction
APPLESCRIPT
}

pick_services() {
  local default_item="$1"
  local service_lines
  service_lines="$(join_lines "${SERVICES[@]}")"
  SERVICE_LINES="${service_lines}" DEFAULT_ITEM="${default_item}" osascript <<'APPLESCRIPT'
set serviceText to system attribute "SERVICE_LINES"
set defaultItem to system attribute "DEFAULT_ITEM"
set AppleScript's text item delimiters to linefeed
set serviceList to text items of serviceText
set AppleScript's text item delimiters to ""

if defaultItem is "" then
	set defaultItems to {}
else
	set defaultItems to {defaultItem}
end if

set chosenServices to choose from list serviceList with prompt "选择要操作的服务，可多选" default items defaultItems OK button name "执行" cancel button name "取消" with multiple selections allowed and empty selection allowed false
if chosenServices is false then
	return ""
end if

set AppleScript's text item delimiters to linefeed
set joinedItems to chosenServices as text
set AppleScript's text item delimiters to ""
return joinedItems
APPLESCRIPT
}

action="$(pick_action)"
if [[ -z "${action}" ]]; then
  exit 0
fi

services=()
case "${action}" in
  up|start|restart|build)
    picked="$(pick_services "rigel-console")"
    [[ -z "${picked}" ]] && exit 0
    while IFS= read -r line; do
      [[ -n "${line}" ]] && services+=("${line}")
    done <<< "${picked}"
    ;;
  logs)
    picked="$(pick_services "rigel-console")"
    [[ -z "${picked}" ]] && exit 0
    while IFS= read -r line; do
      [[ -n "${line}" ]] && services+=("${line}")
    done <<< "${picked}"
    ;;
  ps|down)
    ;;
esac

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
