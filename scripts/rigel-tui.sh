#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLI_SCRIPT="${SCRIPT_DIR}/rigel.sh"

ACTIONS=(
  "up|打包并启动服务|执行 docker compose up -d --build|1"
  "start|启动已构建服务|执行 docker compose up -d|1"
  "restart|重建并重启服务|对选中服务重新构建并启动|1"
  "build|仅构建服务镜像|只执行 docker compose build|1"
  "logs|查看服务日志|持续查看选中服务日志|1"
  "ps|查看服务状态|执行 docker compose ps|0"
  "down|停止当前环境|执行 docker compose down|0"
)

SERVICES=(
  "postgres|PostgreSQL 数据库"
  "redis|Redis 缓存"
  "rigel-jd-collector|京东联盟采集服务"
  "rigel-build-engine|价格整理与 AI 分析服务"
  "rigel-console|前后台入口服务"
)

ACTION_INDEX=0
SERVICE_INDEX=0
CONFIRM_INDEX=0
STEP="action"
SELECTED_ACTION=""
SELECTED_SERVICES=()
SERVICE_FLAGS=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/rigel-tui.sh

Keys:
  ↑/↓ or j/k  move
  Space       toggle service
  Enter       confirm
  b           back
  q           quit
EOF
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

cleanup() {
  tput cnorm 2>/dev/null || true
  stty echo 2>/dev/null || true
}

init_env() {
  require_tool docker
  require_tool tput
  if [[ ! -f "${CORE_DIR}/.env" ]]; then
    echo ".env not found under ${CORE_DIR}" >&2
    echo "copy .env.example to .env first" >&2
    exit 1
  fi
  if [[ ! -x "${CLI_SCRIPT}" ]]; then
    echo "missing executable script: ${CLI_SCRIPT}" >&2
    exit 1
  fi
}

parse_action() {
  local line="${ACTIONS[$1]}"
  IFS='|' read -r ACTION_KEY ACTION_TITLE ACTION_DESC ACTION_NEEDS_SERVICES <<<"${line}"
}

parse_service() {
  local line="${SERVICES[$1]}"
  IFS='|' read -r SERVICE_KEY SERVICE_DESC <<<"${line}"
}

init_service_flags() {
  SERVICE_FLAGS=()
  local action_key="$1"
  local i
  for ((i = 0; i < ${#SERVICES[@]}; i++)); do
    if [[ "${action_key}" == "logs" ]]; then
      parse_service "$i"
      if [[ "${SERVICE_KEY}" == "rigel-console" ]]; then
        SERVICE_FLAGS+=(1)
      else
        SERVICE_FLAGS+=(0)
      fi
    else
      SERVICE_FLAGS+=(1)
    fi
  done
}

collect_selected_services() {
  SELECTED_SERVICES=()
  local i
  for ((i = 0; i < ${#SERVICES[@]}; i++)); do
    if [[ "${SERVICE_FLAGS[$i]}" == "1" ]]; then
      parse_service "$i"
      SELECTED_SERVICES+=("${SERVICE_KEY}")
    fi
  done
}

term_size() {
  ROWS=$(tput lines)
  COLS=$(tput cols)
}

draw_line() {
  local row="$1"
  tput cup "${row}" 0
  printf '%*s' "${COLS}" '' | tr ' ' '─'
}

draw_text() {
  local row="$1"
  local col="$2"
  local text="$3"
  tput cup "${row}" "${col}"
  printf '%.*s' $((COLS - col - 1)) "${text}"
}

render_header() {
  draw_text 0 1 "givezj8 tui"
  draw_text 1 1 "一个带步骤选择、服务勾选和执行确认的 Rigel 终端工具"
  draw_line 2
}

render_footer() {
  local message="$1"
  draw_line $((ROWS - 3))
  draw_text $((ROWS - 2)) 1 "↑/↓ 或 j/k 移动  Space 选择  Enter 确认  b 返回  q 退出  |  ${message}"
}

render_action_step() {
  draw_text 4 1 "第 1/3 步"
  draw_text 5 1 "选择要执行的动作"
  local row=7
  local i
  for ((i = 0; i < ${#ACTIONS[@]}; i++)); do
    parse_action "$i"
    tput cup "${row}" 2
    if [[ "$i" -eq "${ACTION_INDEX}" ]]; then
      tput rev
      printf "▶ %s" "${ACTION_TITLE}"
      tput sgr0
    else
      printf "%d. %s" $((i + 1)) "${ACTION_TITLE}"
    fi
    row=$((row + 1))
  done
  parse_action "${ACTION_INDEX}"
  draw_line $((row + 1))
  draw_text $((row + 3)) 1 "${ACTION_TITLE}"
  draw_text $((row + 4)) 1 "${ACTION_DESC}"
  render_footer "${ACTION_KEY}"
}

render_services_step() {
  draw_text 4 1 "第 2/3 步"
  draw_text 5 1 "选择要操作的服务"
  parse_action "${ACTION_INDEX}"
  draw_text 6 1 "当前动作：${ACTION_TITLE}"
  local row=8
  local i marker
  for ((i = 0; i < ${#SERVICES[@]}; i++)); do
    parse_service "$i"
    if [[ "${SERVICE_FLAGS[$i]}" == "1" ]]; then
      marker="[x]"
    else
      marker="[ ]"
    fi
    tput cup "${row}" 2
    if [[ "$i" -eq "${SERVICE_INDEX}" ]]; then
      tput rev
      printf "%s %s" "${marker}" "${SERVICE_KEY}"
      tput sgr0
    else
      printf "%s %s" "${marker}" "${SERVICE_KEY}"
    fi
    draw_text "${row}" 32 "${SERVICE_DESC}"
    row=$((row + 1))
  done
  collect_selected_services
  draw_line $((row + 1))
  draw_text $((row + 3)) 1 "已选服务"
  if [[ "${#SELECTED_SERVICES[@]}" -gt 0 ]]; then
    draw_text $((row + 4)) 1 "$(IFS=', '; echo "${SELECTED_SERVICES[*]}")"
  else
    draw_text $((row + 4)) 1 "未选择任何服务"
  fi
  render_footer "空格切换服务"
}

render_confirm_step() {
  collect_selected_services
  parse_action "${ACTION_INDEX}"
  local options=("执行" "返回上一步" "退出")
  draw_text 4 1 "第 3/3 步"
  draw_text 5 1 "确认后将直接执行命令"
  local cmd="./scripts/rigel.sh ${ACTION_KEY}"
  if [[ "${#SELECTED_SERVICES[@]}" -gt 0 ]]; then
    cmd+=" $(printf '%s ' "${SELECTED_SERVICES[@]}")"
  fi
  draw_text 7 1 "即将执行"
  draw_text 8 2 "${cmd}"
  draw_text 10 1 "动作说明"
  draw_text 11 2 "${ACTION_DESC}"
  local row=13
  local i
  for ((i = 0; i < ${#options[@]}; i++)); do
    tput cup "${row}" 2
    if [[ "$i" -eq "${CONFIRM_INDEX}" ]]; then
      tput rev
      printf "%d. %s" $((i + 1)) "${options[$i]}"
      tput sgr0
    else
      printf "%d. %s" $((i + 1)) "${options[$i]}"
    fi
    row=$((row + 1))
  done
  render_footer "回车确认"
}

render() {
  term_size
  clear
  render_header
  case "${STEP}" in
    action) render_action_step ;;
    services) render_services_step ;;
    confirm) render_confirm_step ;;
  esac
}

read_key() {
  local key
  IFS= read -rsn1 key || return 1
  if [[ "${key}" == $'\x1b' ]]; then
    local rest
    IFS= read -rsn2 rest || true
    key+="${rest}"
  fi
  printf '%s' "${key}"
}

execute_command() {
  collect_selected_services
  parse_action "${ACTION_INDEX}"
  clear
  local cmd=("${CLI_SCRIPT}" "${ACTION_KEY}")
  if [[ "${ACTION_NEEDS_SERVICES}" == "1" ]]; then
    cmd+=("${SELECTED_SERVICES[@]}")
  fi
  echo "执行命令:"
  printf '  %q ' "${cmd[@]}"
  echo
  echo
  cd "${CORE_DIR}"
  "${cmd[@]}"
}

main_loop() {
  trap cleanup EXIT
  tput civis
  while true; do
    render
    key="$(read_key)" || break
    case "${STEP}" in
      action)
        case "${key}" in
          $'\x1b[A'|k) ACTION_INDEX=$(((ACTION_INDEX - 1 + ${#ACTIONS[@]}) % ${#ACTIONS[@]})) ;;
          $'\x1b[B'|j) ACTION_INDEX=$(((ACTION_INDEX + 1) % ${#ACTIONS[@]})) ;;
          "")
            parse_action "${ACTION_INDEX}"
            if [[ "${ACTION_NEEDS_SERVICES}" == "1" ]]; then
              init_service_flags "${ACTION_KEY}"
              SERVICE_INDEX=0
              STEP="services"
            else
              CONFIRM_INDEX=0
              STEP="confirm"
            fi
            ;;
          q) break ;;
        esac
        ;;
      services)
        case "${key}" in
          $'\x1b[A'|k) SERVICE_INDEX=$(((SERVICE_INDEX - 1 + ${#SERVICES[@]}) % ${#SERVICES[@]})) ;;
          $'\x1b[B'|j) SERVICE_INDEX=$(((SERVICE_INDEX + 1) % ${#SERVICES[@]})) ;;
          " ")
            if [[ "${SERVICE_FLAGS[$SERVICE_INDEX]}" == "1" ]]; then
              SERVICE_FLAGS[$SERVICE_INDEX]=0
            else
              SERVICE_FLAGS[$SERVICE_INDEX]=1
            fi
            ;;
          "")
            collect_selected_services
            if [[ "${#SELECTED_SERVICES[@]}" -gt 0 ]]; then
              CONFIRM_INDEX=0
              STEP="confirm"
            fi
            ;;
          b) STEP="action" ;;
          q) break ;;
        esac
        ;;
      confirm)
        case "${key}" in
          $'\x1b[A'|k) CONFIRM_INDEX=$(((CONFIRM_INDEX - 1 + 3) % 3)) ;;
          $'\x1b[B'|j) CONFIRM_INDEX=$(((CONFIRM_INDEX + 1) % 3)) ;;
          "")
            case "${CONFIRM_INDEX}" in
              0)
                execute_command
                return 0
                ;;
              1)
                parse_action "${ACTION_INDEX}"
                if [[ "${ACTION_NEEDS_SERVICES}" == "1" ]]; then
                  STEP="services"
                else
                  STEP="action"
                fi
                ;;
              2)
                break
                ;;
            esac
            ;;
          b)
            parse_action "${ACTION_INDEX}"
            if [[ "${ACTION_NEEDS_SERVICES}" == "1" ]]; then
              STEP="services"
            else
              STEP="action"
            fi
            ;;
          q) break ;;
        esac
        ;;
    esac
  done
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  init_env
  main_loop
}

main "$@"
