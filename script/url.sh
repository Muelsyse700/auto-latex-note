#!/bin/bash

# @description: 将 URL 转义为 LaTeX 安全格式并复制到剪贴板

RESET='\033[0m'
GREEN='\033[32m'
CYAN='\033[36m'

usage() {
    printf '%b\n' "${CYAN}用法:${RESET} $(basename "$0") [选项]"
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

read -r -p "URL: " url

escaped=$(printf '%s' "$url" | sed \
    -e 's/\\/\\textbackslash{}/g' \
    -e 's/\([#$%&_{}]\)/\\\1/g' \
    -e 's/~/\\textasciitilde{}/g' \
    -e 's/\^/\\textasciicircum{}/g')

printf '%s' "$escaped" | pbcopy

printf '\n%b\n' "${GREEN}已复制到剪贴板：${RESET}"
printf '%s\n' "$escaped"