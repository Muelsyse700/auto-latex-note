#!/bin/bash

# @description: 将 URL 转义为 LaTeX 安全格式并复制到剪贴板

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

usage() {
    printf '%b\n' "${CYAN}用法:${RESET} ${YELLOW}$(basename "$0")${RESET} [选项]"
    printf '%b\n' "将用户输入的 URL 转义为 LaTeX 安全格式，并复制到剪贴板。"
    printf '\n'
    printf '%b\n' "${CYAN}选项:${RESET}"
    printf '  -h, --help    显示此帮助信息\n'
    printf '\n'
    printf '%b\n' "${CYAN}说明:${RESET}"
    printf '  该脚本会提示输入 URL，然后进行转义处理，'
    printf '  并将结果复制到系统剪贴板。\n'
    printf '\n'
    printf '%b\n' "${CYAN}防呆机制:${RESET}"
    printf '  除 -h/--help 外的所有命令行参数均被忽略，不会影响正常执行。\n'
    exit 0
}

# 防呆机制：若第一个参数是 -h 或 --help 则显示帮助，否则忽略所有其它参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi
# 忽略其它所有参数（如果有），继续执行正常流程

# 注意：read -p 不解释 \033 转义，故用 printf '%b' 输出提示（保持提示走 stderr）
printf '%b' "${CYAN}URL: ${RESET}" >&2
read -r url

# 逐字符单次转义：每个原字符只映射一次，已插入的宏不会被后续规则二次处理
# （原先用 sed 逐条替换时，\textbackslash{} 的大括号会被后面的转义规则变成 \{\}）
escape_latex_url() {
    local s="$1" out="" ch i
    for (( i = 0; i < ${#s}; i++ )); do
        ch="${s:i:1}"
        case "$ch" in
            '\') out+='\textbackslash{}' ;;
            '~') out+='\textasciitilde{}' ;;
            '^') out+='\textasciicircum{}' ;;
            '#'|'$'|'%'|'&'|'_'|'{'|'}') out+="\\${ch}" ;;
            *)   out+="${ch}" ;;
        esac
    done
    printf '%s' "$out"
}

escaped="$(escape_latex_url "$url")"

printf '%s' "$escaped" | pbcopy

printf '\n%b\n' "${GREEN}已复制到剪贴板：${RESET}"
printf '%s\n' "$escaped"