#!/bin/zsh

# @description: 自动启动 VirtualHere，检测 HP 136a 连接后启动 HP 打印

# ===== 颜色定义 =====
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

# ===== 配置 =====
VIRTUALHERE_BIN="$HOME/Applications/VirtualHereUniversal.app/Contents/MacOS/VirtualHereUniversal"
HP_APP="HP"
HP_USB_VENDOR="1008"       # 0x03f0
HP_USB_PRODUCT="61994"     # 0xf22a
PRINTER_CONNECT_TIMEOUT=60 # 最长等待打印机连接的时间（秒）
PRINTER_STABLE_WAIT=2 # 检测到打印机后，等待设备稳定的时间（秒）
HP_START_WAIT=3 # HP 启动后等待时间（秒）


# ===== 帮助信息 =====
usage() {
    printf "${CYAN}用法：${RESET}\n"
    printf "  ${YELLOW}%s${RESET} [工作目录] [文件名]\n" "$(basename "$0")"
    printf "\n${CYAN}选项：${RESET}\n"
    printf "  -h, --help  显示此帮助信息\n"
    printf "\n${CYAN}说明：${RESET}\n"
    printf "  自动启动 VirtualHere，等待 HP 136a 连接后启动 HP。\n"
    printf "  若省略工作目录，则使用当前目录。\n"
    printf "  若省略文件名，则列出工作目录下可打印文件供选择。\n"
    printf "\n${CYAN}示例：${RESET}\n"
    printf "  %s\n" "$(basename "$0")"
    printf "  %s ~/Documents\n" "$(basename "$0")"
    printf "  %s ~/Documents homework.pdf\n" "$(basename "$0")"
    exit 0
}


# ===== 参数解析 =====
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if (( $# > 2 )); then
    printf "${RED}错误：${RESET}参数过多\n"
    printf "用法：${YELLOW}%s${RESET} [工作目录] [文件名]\n" "$(basename "$0")"
    exit 1
fi

WORK_DIR="${1:-$PWD}"
FILE_ARG="${2:-}"

if [[ ! -d "$WORK_DIR" ]]; then
    printf "${RED}错误：${RESET}工作目录不存在：${YELLOW}%s${RESET}\n" "$WORK_DIR"
    exit 1
fi

WORK_DIR="$(cd "$WORK_DIR" && pwd)"

if ! cd "$WORK_DIR"; then
    printf "${RED}错误：${RESET}无法进入工作目录：${YELLOW}%s${RESET}\n" "$WORK_DIR"
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

if [[ -n "$FILE_ARG" ]]; then
    if [[ ! -f "$WORK_DIR/$FILE_ARG" ]]; then
        printf "${RED}错误：${RESET}指定文件不存在：${YELLOW}%s${RESET}\n" \
            "$WORK_DIR/$FILE_ARG"
        exit 1
    fi

    file="$WORK_DIR/$FILE_ARG"

    printf "\n${GREEN}已选择：${RESET}${YELLOW}%s${RESET}\n" \
        "$FILE_ARG"

else
    # 扫描当前目录中的可打印文件
    files=(
        *.(pdf|PDF|doc|DOC|docx|DOCX|ppt|PPT|pptx|PPTX|xls|XLS|xlsx|XLSX|jpg|JPG|jpeg|JPEG|png|PNG|tif|TIF|tiff|TIFF|txt|TXT|rtf|RTF)(N)
    )

    if (( ${#files} == 0 )); then
        printf "${RED}错误：${RESET}当前目录没有找到可打印的文件\n"
        exit 1
    fi

    printf "\n${PURPLE}=== 请选择打印文件 ===${RESET}\n\n"

    MAX_LEN=0

    for f in "${files[@]}"; do
        LEN=${#f}
        (( LEN > MAX_LEN )) && MAX_LEN=$LEN
    done

    COL_WIDTH=$(( MAX_LEN + 2 ))

    INDEX=1

    for f in "${files[@]}"; do
        printf "${PURPLE}[%d]${RESET} ${YELLOW}%-*s${RESET}\n" \
            "$INDEX" "$COL_WIDTH" "$f"
        INDEX=$(( INDEX + 1 ))
    done

    echo

    while true; do
        printf "${CYAN}请输入序号：${RESET}"
        read -r choice

        if [[ "$choice" == <-> ]] &&
            (( choice >= 1 && choice <= ${#files} )); then
            break
        fi

        printf "${RED}请输入有效的数字序号（1-%d）${RESET}\n" \
            "${#files}"
    done

    file="$WORK_DIR/${files[$choice]}"

    printf "\n${GREEN}已选择：${RESET}${YELLOW}%s${RESET}\n" \
        "${files[$choice]}"
fi

# ===== 检查 HP 136a 是否已连接 =====
is_printer_connected() {
    ioreg -p IOUSB -l -w 0 2>/dev/null |
        awk -v vid="$HP_USB_VENDOR" -v pid="$HP_USB_PRODUCT" '
            BEGIN {
                RS = "\\+-o "
                found = 0
            }

            {
                vendor = ""
                product = ""

                if (match($0, /"idVendor" = [0-9]+/)) {
                    vendor = substr($0, RSTART, RLENGTH)
                    sub(/^.*= /, "", vendor)
                }

                if (match($0, /"idProduct" = [0-9]+/)) {
                    product = substr($0, RSTART, RLENGTH)
                    sub(/^.*= /, "", product)
                }

                if (vendor == vid && product == pid) {
                    found = 1
                }
            }

            END {
                exit (found ? 0 : 1)
            }
        '
}


# ===== 关闭 VirtualHere =====
stop_virtualhere() {
    printf "${CYAN}正在关闭 VirtualHere...${RESET}\n"

    # 优先尝试关闭本次启动的进程
    if [[ -n "${VIRTUALHERE_PID:-}" ]] &&
        kill -0 "$VIRTUALHERE_PID" 2>/dev/null; then
        kill "$VIRTUALHERE_PID" 2>/dev/null
    else
        # 如果 PID 已经失效，尝试通过 AppleScript 退出应用
        osascript \
            -e 'tell application "VirtualHereUniversal" to quit' \
            >/dev/null 2>&1
    fi
}


# ===== 启动打印环境 =====
printf "\n${PURPLE}=== 正在启动打印环境 ===${RESET}\n"

# 启动 VirtualHere
"$VIRTUALHERE_BIN" >/dev/null 2>&1 &
VIRTUALHERE_PID=$!

ELAPSED=0

while true; do
    if is_printer_connected; then
        break
    fi

    if (( ELAPSED >= PRINTER_CONNECT_TIMEOUT )); then
        printf "\n${RED}错误：${RESET}等待打印机连接超时（%d 秒）\n" \
            "$PRINTER_CONNECT_TIMEOUT"

        printf "${YELLOW}请检查 VirtualHere 是否已连接打印机。${RESET}\n"

        stop_virtualhere
        exit 1
    fi

    sleep 1
    (( ELAPSED++ ))

    printf "\r${CYAN}等待打印机连接：%d/%d 秒${RESET}" \
        "$ELAPSED" "$PRINTER_CONNECT_TIMEOUT"
done

printf "\n\n${GREEN}✓${RESET} 已检测到 HP 136a！\n"

# 等待设备稳定
sleep "$PRINTER_STABLE_WAIT"

# 再次确认设备仍然存在
if ! is_printer_connected; then
    printf "${RED}错误：${RESET}打印机在启动 HP 前断开了连接\n"
    stop_virtualhere
    exit 1
fi


# ===== 启动 HP =====
printf "${CYAN}正在启动 HP...${RESET}\n"

if ! open -a "$HP_APP" "$file"; then
    printf "${RED}错误：${RESET}无法启动 HP 或打开打印文件\n"
    stop_virtualhere
    exit 1
fi

sleep "$HP_START_WAIT"


# ===== 等待 HP 处理完成 =====
printf "${CYAN}等待 HP 处理完成...${RESET}\n"

while pgrep -x "HP" >/dev/null 2>&1; do
    sleep 1
done


# ===== 关闭打印环境 =====
printf "\n${GREEN}✓${RESET} HP 已退出，准备关闭 VirtualHere\n"

stop_virtualhere

printf "\n${GREEN}✓${RESET} 打印环境已关闭\n"