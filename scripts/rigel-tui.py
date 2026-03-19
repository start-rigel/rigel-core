#!/usr/bin/env python3

import curses
import os
import subprocess
import sys
from dataclasses import dataclass
from typing import List, Optional, Sequence, Tuple


@dataclass(frozen=True)
class ActionItem:
    key: str
    title: str
    description: str
    needs_services: bool


ACTIONS: Sequence[ActionItem] = (
    ActionItem("up", "打包并启动服务", "执行 docker compose up -d --build。", True),
    ActionItem("start", "启动已构建服务", "执行 docker compose up -d。", True),
    ActionItem("restart", "重建并重启服务", "对选中服务重新构建并启动。", True),
    ActionItem("build", "仅构建服务镜像", "只执行 docker compose build。", True),
    ActionItem("logs", "查看服务日志", "持续查看选中服务日志。", True),
    ActionItem("ps", "查看服务状态", "执行 docker compose ps。", False),
    ActionItem("down", "停止当前环境", "执行 docker compose down。", False),
)

SERVICES: Sequence[Tuple[str, str]] = (
    ("postgres", "PostgreSQL 数据库"),
    ("redis", "Redis 缓存"),
    ("rigel-jd-collector", "京东联盟采集服务"),
    ("rigel-build-engine", "价格整理与 AI 分析服务"),
    ("rigel-console", "前后台入口服务"),
)


def core_paths() -> Tuple[str, str]:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    core_dir = os.path.dirname(script_dir)
    cli_script = os.path.join(script_dir, "rigel.sh")
    return core_dir, cli_script


def ensure_environment(core_dir: str, cli_script: str) -> None:
    if not os.path.exists(cli_script):
        raise RuntimeError(f"missing script: {cli_script}")
    if not os.path.exists(os.path.join(core_dir, ".env")):
        raise RuntimeError(f"missing env file: {core_dir}/.env")


def draw_header(stdscr: "curses._CursesWindow", title: str, subtitle: str) -> int:
    _, width = stdscr.getmaxyx()
    header_color = curses.color_pair(2)
    stdscr.attron(header_color)
    stdscr.addstr(0, 1, "givezj8 tui")
    stdscr.hline(1, 0, curses.ACS_HLINE, max(0, width - 1))
    stdscr.attroff(header_color)
    stdscr.addstr(2, 1, title, curses.A_BOLD)
    stdscr.addstr(3, 1, subtitle)
    stdscr.hline(4, 0, curses.ACS_HLINE, max(0, width - 1))
    return 6


def draw_footer(stdscr: "curses._CursesWindow", message: str) -> None:
    height, width = stdscr.getmaxyx()
    footer = f"↑/↓ 移动  Space 选择  Enter 确认  b 返回  q 退出  |  {message}"
    stdscr.hline(height - 3, 0, curses.ACS_HLINE, max(0, width - 1))
    stdscr.addstr(height - 2, 1, footer[: max(0, width - 2)], curses.color_pair(3))


def draw_action_menu(stdscr: "curses._CursesWindow", index: int) -> None:
    stdscr.clear()
    top = draw_header(stdscr, "第 1/3 步：选择动作", "先确定这次要执行的 compose 操作。")
    for i, item in enumerate(ACTIONS):
        style = curses.A_REVERSE | curses.A_BOLD if i == index else curses.A_NORMAL
        stdscr.addstr(top + i, 2, f"{i + 1}. {item.title}", style)
    stdscr.hline(top + len(ACTIONS) + 1, 0, curses.ACS_HLINE, max(0, stdscr.getmaxyx()[1] - 1))
    selected = ACTIONS[index]
    stdscr.addstr(top + len(ACTIONS) + 3, 1, selected.title, curses.A_BOLD)
    stdscr.addstr(top + len(ACTIONS) + 4, 1, selected.description)
    draw_footer(stdscr, selected.key)
    stdscr.refresh()


def draw_service_menu(stdscr: "curses._CursesWindow", action: ActionItem, index: int, selected: List[bool]) -> None:
    stdscr.clear()
    top = draw_header(stdscr, "第 2/3 步：选择服务", f"动作：{action.title}")
    for i, (service, desc) in enumerate(SERVICES):
        marker = "[x]" if selected[i] else "[ ]"
        style = curses.A_REVERSE | curses.A_BOLD if i == index else curses.A_NORMAL
        stdscr.addstr(top + i, 2, f"{marker} {service}", style)
        stdscr.addstr(top + i, 34, desc[: max(0, stdscr.getmaxyx()[1] - 36)])
    stdscr.hline(top + len(SERVICES) + 1, 0, curses.ACS_HLINE, max(0, stdscr.getmaxyx()[1] - 1))
    chosen = [name for i, (name, _) in enumerate(SERVICES) if selected[i]]
    stdscr.addstr(top + len(SERVICES) + 3, 1, "已选服务", curses.A_BOLD)
    stdscr.addstr(top + len(SERVICES) + 4, 1, ", ".join(chosen) if chosen else "未选择任何服务")
    draw_footer(stdscr, "空格切换服务")
    stdscr.refresh()


def draw_confirm(
    stdscr: "curses._CursesWindow",
    action: ActionItem,
    services: Sequence[str],
    index: int,
) -> None:
    options = ["执行", "返回上一步", "退出"]
    stdscr.clear()
    top = draw_header(stdscr, "第 3/3 步：确认执行", "确认后会退出 TUI 并直接执行命令。")
    command = f"./scripts/rigel.sh {action.key}" + (f" {' '.join(services)}" if services else "")
    stdscr.addstr(top, 1, "即将执行", curses.A_BOLD)
    stdscr.addstr(top + 1, 2, command)
    stdscr.addstr(top + 3, 1, "动作说明", curses.A_BOLD)
    stdscr.addstr(top + 4, 2, action.description)
    for i, option in enumerate(options):
        style = curses.A_REVERSE | curses.A_BOLD if i == index else curses.A_NORMAL
        stdscr.addstr(top + 7 + i, 2, f"{i + 1}. {option}", style)
    draw_footer(stdscr, "回车确认")
    stdscr.refresh()


def menu_loop(stdscr: "curses._CursesWindow") -> Tuple[Optional[ActionItem], List[str]]:
    curses.curs_set(0)
    curses.use_default_colors()
    curses.start_color()
    curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_CYAN)
    curses.init_pair(2, curses.COLOR_CYAN, -1)
    curses.init_pair(3, curses.COLOR_WHITE, -1)
    stdscr.keypad(True)

    step = "action"
    action_index = 0
    service_index = 0
    confirm_index = 0
    selected_services = [False for _ in SERVICES]

    while True:
        action = ACTIONS[action_index]
        if step == "action":
            draw_action_menu(stdscr, action_index)
        elif step == "services":
            draw_service_menu(stdscr, action, service_index, selected_services)
        else:
            chosen_services = [name for i, (name, _) in enumerate(SERVICES) if selected_services[i]]
            draw_confirm(stdscr, action, chosen_services, confirm_index)

        key = stdscr.getch()

        if key in (ord("q"), ord("Q")):
            return None, []

        if step == "action":
            if key in (curses.KEY_UP, ord("k")):
                action_index = (action_index - 1) % len(ACTIONS)
            elif key in (curses.KEY_DOWN, ord("j")):
                action_index = (action_index + 1) % len(ACTIONS)
            elif key in (10, 13, curses.KEY_ENTER):
                if action.needs_services:
                    selected_services = [action.key != "logs" for _ in SERVICES]
                    if action.key == "logs":
                        selected_services = [name == "rigel-console" for name, _ in SERVICES]
                    service_index = 0
                    step = "services"
                else:
                    confirm_index = 0
                    step = "confirm"

        elif step == "services":
            if key in (ord("b"), ord("B")):
                step = "action"
            elif key in (curses.KEY_UP, ord("k")):
                service_index = (service_index - 1) % len(SERVICES)
            elif key in (curses.KEY_DOWN, ord("j")):
                service_index = (service_index + 1) % len(SERVICES)
            elif key == ord(" "):
                selected_services[service_index] = not selected_services[service_index]
            elif key in (10, 13, curses.KEY_ENTER):
                if any(selected_services):
                    confirm_index = 0
                    step = "confirm"

        elif step == "confirm":
            if key in (ord("b"), ord("B")):
                step = "services" if action.needs_services else "action"
            elif key in (curses.KEY_UP, ord("k")):
                confirm_index = (confirm_index - 1) % 3
            elif key in (curses.KEY_DOWN, ord("j")):
                confirm_index = (confirm_index + 1) % 3
            elif key in (10, 13, curses.KEY_ENTER):
                if confirm_index == 0:
                    services = [name for i, (name, _) in enumerate(SERVICES) if selected_services[i]]
                    return action, services
                if confirm_index == 1:
                    step = "services" if action.needs_services else "action"
                if confirm_index == 2:
                    return None, []


def main() -> int:
    core_dir, cli_script = core_paths()
    ensure_environment(core_dir, cli_script)

    action, services = curses.wrapper(menu_loop)
    if action is None:
        return 0

    command = [cli_script, action.key]
    if action.needs_services:
        command.extend(services)

    print("执行命令:")
    print(" ", " ".join(command))
    print()
    return subprocess.call(command, cwd=core_dir)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)
