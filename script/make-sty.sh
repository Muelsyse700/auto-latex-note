#!/bin/bash

# @description: 将模板文件合并生成latexNote.sty包文件

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'

# 显示帮助信息
usage() {
    printf '%b\n' "${CYAN}用法:${RESET} $0 [目标目录]"
    printf '%b\n' ""
    printf '%b\n' "将模板文件合并生成 ${YELLOW}latexNote.sty${RESET} 包文件。"
    printf '%b\n' "如果指定目标目录，则生成到该目录下；否则生成到当前工作目录。"
    printf '%b\n' ""
    printf '%b\n' "${CYAN}示例:${RESET}"
    printf '%b\n' "  $0               # 生成到当前目录"
    printf '%b\n' "  $0 ~/mytex       # 生成到 ~/mytex 目录"
    printf '%b\n' "  $0 /path/to/dir  # 生成到 /path/to/dir"
    exit 0
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi
TARGET_DIR="${1:-.}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" # 获取脚本所在目录
TEMPLATE="$SCRIPT_DIR/../template" # 模板文件夹位于上级目录的 template/ 下
mkdir -p "$TARGET_DIR" || { printf "${RED}错误：无法创建目录 $TARGET_DIR${RESET}\n" >&2; exit 1; } # 确保目标目录存在

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
OUTPUT="$TARGET_DIR/latexNote.sty"

FILES=(
    "$TEMPLATE/usedPackages.tex"
    "$TEMPLATE/baseSettings.tex"
    "$TEMPLATE/myCommands.tex"
)

# 检查模板文件是否存在
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        printf "${RED}错误：找不到模板文件：$file${RESET}\n" >&2
        exit 1
    fi
done

# 合并生成 .sty 文件
{
    printf '%s\n' '\NeedsTeXFormat{LaTeX2e}'
    printf '%s\n' '\ProvidesPackage{latexNote}'
    printf '\n'

    cat "${FILES[0]}"
    printf '\n'

    cat "${FILES[1]}"
    printf '\n'

    cat "${FILES[2]}"
    printf '\n'

    printf '%s\n' '\endinput'
} > "$OUTPUT"

printf "${GREEN}✓ 已生成 ${YELLOW}%s${RESET}\n" "$OUTPUT"