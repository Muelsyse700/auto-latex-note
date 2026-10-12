#!/bin/zsh

# @description: 自动启动打印服务

# ===== 颜色定义 =====
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

# ===== 配置 =====
VIRTUALHERE_BIN="$HOME/Applications/VirtualHereUniversal.app/Contents/MacOS/VirtualHereUniversal"
HP_APP="HP"

# VirtualHere 启动后等待时间（秒）
VIRTUALHERE_WAIT=3

# HP 启动后等待时间（秒）
HP_START_WAIT=3

# ===== 帮助信息 =====
usage() {
    printf "${CYAN}用法：${RESET}\n"
    printf "  %s [工作目录] [文件名]\n" "$(basename "$0")"
    printf "\n${CYAN}选项：${RESET}\n"
    printf "  -h, --help  显示此帮助信息\n"
    printf "\n${CYAN}说明：${RESET}\n"
    printf "  自动启动 VirtualHere 与 HP 打印服务，打印指定文件。\n"
    printf "  若省略工作目录，则使用当前目录。\n"
    printf "  若省略文件名，则列出工作目录下可打印文件供选择。\n"
    printf "\n${CYAN}示例：${RESET}\n"
    printf "  %s\n" "$(basename "$0")"
    printf "  %s ~/Documents\n" "$(basename "$0")"
    printf "  %s ~/Documents homework.pdf\n" "$(basename "$0")"
    exit 0
}

# ===== 参数解析 =====
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

if [ "$#" -gt 2 ]; then
    printf "${RED}错误：${RESET}参数过多\n"
    printf "用法：%s [工作目录] [文件名]\n" "$(basename "$0")"
    exit 1
fi

WORK_DIR="${1:-$PWD}"
FILE_ARG="$2"

if [ ! -d "$WORK_DIR" ]; then
    printf "${RED}错误：${RESET}工作目录不存在：%s\n" "$WORK_DIR"
    exit 1
fi

WORK_DIR="$(cd "$WORK_DIR" && pwd)"

if ! cd "$WORK_DIR"; then
    printf "${RED}错误：${RESET}无法进入工作目录：%s\n" "$WORK_DIR"
    exit 1
fi

# ===== 检查 VirtualHere 客户端 =====
if [[ ! -x "$VIRTUALHERE_BIN" ]]; then
    printf "${RED}错误：${RESET}找不到 VirtualHere 客户端：\n"
    printf "  ${YELLOW}%s${RESET}\n" "$VIRTUALHERE_BIN"
    exit 1
fi

# ===== 选择文件 =====
file=""

if [ -n "$FILE_ARG" ]; then
    if [ ! -f "$WORK_DIR/$FILE_ARG" ]; then
        printf "${RED}错误：${RESET}指定文件不存在：%s\n" "$WORK_DIR/$FILE_ARG"
        exit 1
    fi
    file="$FILE_ARG"
    printf "\n${GREEN}已选择：${RESET}${YELLOW}%s${RESET}\n" "$file"
else
    # 扫描当前目录中的可打印文件
    files=(
        *.(pdf|PDF|doc|DOC|docx|DOCX|ppt|PPT|pptx|PPTX|xls|XLS|xlsx|XLSX|jpg|JPG|jpeg|JPEG|png|PNG|tif|TIF|tiff|TIFF|txt|TXT|rtf|RTF)(N)
    )

    if (( ${#files} == 0 )); then
        printf "${RED}错误：${RESET}当前目录没有找到可打印的文件\n"
        exit 1
    fi

    printf "\n${CYAN}=== 请选择打印文件 ===${RESET}\n\n"

    # 计算最大名称长度
    MAX_LEN=0
    for f in "${files[@]}"; do
        LEN=${#f}
        [ "$LEN" -gt "$MAX_LEN" ] && MAX_LEN=$LEN
    done
    COL_WIDTH=$((MAX_LEN + 2))

    INDEX=1
    for f in "${files[@]}"; do
        printf "${PURPLE}[%d]${RESET} ${YELLOW}%-*s${RESET}\n" "$INDEX" "$COL_WIDTH" "$f"
        INDEX=$((INDEX + 1))
    done
    echo

    while true; do
        printf "${CYAN}请输入序号：\n${RESET}"
        read -r choice
        if [[ "$choice" == <-> ]] && (( choice >= 1 && choice <= ${#files} )); then
            break
        fi
        printf "${RED}请输入有效的数字序号（1-%d）${RESET}\n" "${#files}"
    done

    file="${files[$choice]}"
    printf "\n${GREEN}已选择：${RESET}${YELLOW}%s${RESET}\n" "$file"
fi

# ===== 启动打印环境 =====
printf "\n${CYAN}=== 正在启动打印环境 ===${RESET}\n"

"$VIRTUALHERE_BIN" >/dev/null 2>&1 &
VIRTUALHERE_PID=$!

printf "${CYAN}等待 VirtualHere 连接 HP 136a...${RESET}\n"
sleep "$VIRTUALHERE_WAIT"

printf "${CYAN}正在启动 HP...${RESET}\n"
open -a "$HP_APP" "$file"

sleep "$HP_START_WAIT"

printf "${CYAN}等待 HP 处理完成...${RESET}\n"
while pgrep -x "HP" >/dev/null 2>&1; do
    sleep 1
done

printf "${GREEN}✓${RESET} HP 已退出，正在关闭 VirtualHere...\n"

# 优先使用 PID
if kill -0 "$VIRTUALHERE_PID" 2>/dev/null; then
    kill "$VIRTUALHERE_PID" 2>/dev/null
else
    # 如果 PID 已经失效，则尝试通过 AppleScript 退出
    osascript -e 'tell application "VirtualHereUniversal" to quit' \
        >/dev/null 2>&1
fi

printf "\n${GREEN}✓${RESET} 打印环境已关闭\n"
