#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"

while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
TARGET_DIR="$(pwd)"

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

usage() {
    printf '%b\n' "${CYAN}note.sh${RESET}"
    printf 'latexNote 工具管理器\n'
    printf '\n'
    printf '%b\n' "${CYAN}用法${RESET}"
    printf '  note.sh              打开工具菜单\n'
    printf '  note.sh -h           显示帮助信息\n'
}

is_hidden() {
    local file="$1"
    grep -q -E '^[[:space:]]*(#[[:space:]]*)?@description\*' "$file" 2>/dev/null
}

get_description() {
    local file="$1"
    local line

    line="$(grep -m 1 -E '^[[:space:]]*(#[[:space:]]*)?@description\*?:?' "$file" 2>/dev/null || true)"

    if [ -n "$line" ]; then
        printf '%s\n' "$line" |
            sed -E 's/^[[:space:]]*(#[[:space:]]*)?@description\*?:?[[:space:]]*//'
    else
        printf '%s' "无描述"
    fi
}

run_script() {
    local script="$1"
    shift

    case "$script" in
        *.py)
            if ! command -v python3 >/dev/null 2>&1; then
                printf '%b\n' "${RED}错误：当前环境未找到 python3${RESET}"
                return 1
            fi

            python3 "$script" "$@"
            ;;

        *.sh)
            "$script" "$@"
            ;;

        *)
            printf '%b\n' "${RED}错误：不支持的脚本类型${RESET}"
            return 1
            ;;
    esac
}

wait_after_execution() {
    local choice

    printf '\n'
    printf '%b' "${CYAN}按 Enter 返回菜单，按 q 退出：${RESET}"
    read -r choice

    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        printf '%b\n' "${GREEN}已退出${RESET}"
        exit 0
    fi
}

show_hidden_menu() {
    local input choice args index script name wait_choice

    while true; do
        printf '\033c'

        printf '%b\n' "${PURPLE}latexNote 隐藏脚本${RESET}"
        printf '%b\n' "${CYAN}当前目录：${RESET}${YELLOW}${TARGET_DIR}${RESET}"
        printf '\n'

        printf '%b\n' "${PURPLE}=== 隐藏脚本 ===${RESET}"

        if [ "${#HIDDEN_SCRIPT_FILES[@]}" -eq 0 ]; then
            printf '  暂无隐藏脚本\n'
        else
            for i in "${!HIDDEN_SCRIPT_FILES[@]}"; do
                number=$((i + 1))

                printf '%b' "${PURPLE}  ${number}${RESET}) "
                printf '%b\n' "${YELLOW}${HIDDEN_SCRIPT_NAMES[$i]}${RESET}"
                printf '     %s\n' "${HIDDEN_SCRIPT_DESCRIPTIONS[$i]}"
            done
        fi

        printf '\n'
        printf '%b\n' "${PURPLE}  b${RESET}) 返回主菜单    ${PURPLE}q${RESET}) 退出"
        printf '\n'

        printf '%b' "${CYAN}请选择：${RESET}"
        read -r input

        if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
            printf '%b\n' "${GREEN}已退出${RESET}"
            exit 0
        fi

        if [ "$input" = "b" ] || [ "$input" = "B" ]; then
            return 0
        fi

        if [ -z "$input" ]; then
            continue
        fi

        read -r choice args <<< "$input"

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            printf '%b\n' "${RED}无效的选项${RESET}"
            sleep 1
            continue
        fi

        index=$((choice - 1))

        if [ "$index" -lt 0 ] || [ "$index" -ge "${#HIDDEN_SCRIPT_FILES[@]}" ]; then
            printf '%b\n' "${RED}无效的选项${RESET}"
            sleep 1
            continue
        fi

        script="${HIDDEN_SCRIPT_FILES[$index]}"
        name="${HIDDEN_SCRIPT_NAMES[$index]}"

        printf '\n%b\n' "${CYAN}正在执行 ${YELLOW}${name}${CYAN} ...${RESET}"

        if [[ "$args" == "-h" || "$args" == "--help" ]]; then
            run_script "$script" "$args"
        else
            run_script "$script" "$TARGET_DIR"
        fi

        printf '\n%b\n' "${GREEN}${name} 执行完成${RESET}"

        printf '\n'
        printf '%b' "${CYAN}按 Enter 返回隐藏脚本菜单，按 q 退出：${RESET}"
        read -r wait_choice

        if [ "$wait_choice" = "q" ] || [ "$wait_choice" = "Q" ]; then
            printf '%b\n' "${GREEN}已退出${RESET}"
            exit 0
        fi
    done
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

if [ $# -gt 0 ]; then
    printf '%b\n' "${RED}错误：${RESET}未知参数 ${YELLOW}$1${RESET}"
    printf '使用 -h 查看帮助信息\n'
    exit 1
fi

declare -a SCRIPT_FILES
declare -a SCRIPT_NAMES
declare -a SCRIPT_DESCRIPTIONS
declare -a HIDDEN_SCRIPT_FILES
declare -a HIDDEN_SCRIPT_NAMES
declare -a HIDDEN_SCRIPT_DESCRIPTIONS

while IFS= read -r -d '' file; do
    name="$(basename "$file")"

    [ "$file" -ef "$SOURCE" ] && continue

    description="$(get_description "$file")"

    if is_hidden "$file"; then
        HIDDEN_SCRIPT_FILES+=("$file")
        HIDDEN_SCRIPT_NAMES+=("$name")
        HIDDEN_SCRIPT_DESCRIPTIONS+=("$description")
    else
        SCRIPT_FILES+=("$file")
        SCRIPT_NAMES+=("$name")
        SCRIPT_DESCRIPTIONS+=("$description")
    fi
done < <(
    find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name "*.sh" -o -name "*.py" \) \
        -print0 |
        sort -z
)

while true; do
    printf '\033c'

    printf '%b\n' "${PURPLE}latexNote 工具${RESET}"
    printf '%b\n' "${CYAN}当前目录：${RESET}${YELLOW}${TARGET_DIR}${RESET}"
    printf '\n'

    printf '%b\n' "${PURPLE}=== 工具链 ===${RESET}"

    printf '%b' "${PURPLE}  1${RESET}) "
    printf '%b\n' "${YELLOW}初始化工具链${RESET}"
    printf '     初始化当前目录的 latexNote 项目\n'

    printf '%b' "${PURPLE}  2${RESET}) "
    printf '%b\n' "${YELLOW}更新模板工具链${RESET}"
    printf '     更新当前目录的 latexNote 模板\n'

    printf '\n'
    printf '%b\n' "${PURPLE}=== 脚本工具 ===${RESET}"

    start=3

    if [ "${#SCRIPT_FILES[@]}" -eq 0 ]; then
        printf '  暂无可用脚本\n'
    else
        for i in "${!SCRIPT_FILES[@]}"; do
            number=$((start + i))

            printf '%b' "${PURPLE}  ${number}${RESET}) "
            printf '%b\n' "${YELLOW}${SCRIPT_NAMES[$i]}${RESET}"
            printf '     %s\n' "${SCRIPT_DESCRIPTIONS[$i]}"
        done
    fi

    printf '\n'
    printf '%b\n' "${PURPLE}  *${RESET}) 显示隐藏脚本    ${PURPLE}q${RESET}) 退出"
    printf '\n'

    printf '%b' "${CYAN}请选择：${RESET}"
    read -r input

    if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
        printf '%b\n' "${GREEN}已退出${RESET}"
        exit 0
    fi

    if [ -z "$input" ]; then
        continue
    fi

    if [ "$input" = "*" ]; then
        show_hidden_menu
        continue
    fi

    read -r choice args <<< "$input"

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        printf '%b\n' "${RED}无效的选项${RESET}"
        sleep 1
        continue
    fi

    if [ "$choice" -eq 1 ]; then
        printf '\n%b\n' "${CYAN}正在执行 ${YELLOW}初始化工具链${CYAN} ...${RESET}"

        if [[ "$args" == "-h" || "$args" == "--help" ]]; then
            run_script "$SCRIPT_DIR/init-update.sh" "$args"
        else
            run_script "$SCRIPT_DIR/init-update.sh" "$TARGET_DIR"
        fi

        printf '\n%b\n' "${GREEN}初始化工具链执行完成${RESET}"
        wait_after_execution
        continue
    fi

    if [ "$choice" -eq 2 ]; then
        printf '\n%b\n' "${CYAN}正在执行 ${YELLOW}更新模板工具链${CYAN} ...${RESET}"

        if [[ "$args" == "-h" || "$args" == "--help" ]]; then
            run_script "$SCRIPT_DIR/init-update.sh" "$args"
        else
            run_script "$SCRIPT_DIR/init-update.sh" "$TARGET_DIR" -u
        fi

        printf '\n%b\n' "${GREEN}更新模板工具链执行完成${RESET}"
        wait_after_execution
        continue
    fi

    index=$((choice - start))

    if [ "$index" -lt 0 ] || [ "$index" -ge "${#SCRIPT_FILES[@]}" ]; then
        printf '%b\n' "${RED}无效的选项${RESET}"
        sleep 1
        continue
    fi

    script="${SCRIPT_FILES[$index]}"
    name="${SCRIPT_NAMES[$index]}"

    printf '\n%b\n' "${CYAN}正在执行 ${YELLOW}${name}${CYAN} ...${RESET}"

    if [[ "$args" == "-h" || "$args" == "--help" ]]; then
        run_script "$script" "$args"
    else
        run_script "$script" "$TARGET_DIR"
    fi

    printf '\n%b\n' "${GREEN}${name} 执行完成${RESET}"
    wait_after_execution
done