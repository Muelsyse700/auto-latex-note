#!/bin/bash

# @description: 清理 LaTeX 编译产生的辅助文件

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

usage() {
    printf '%b\n' "${CYAN}用法:${RESET} ${YELLOW}$(basename "$0")${RESET} [选项] [目录]"
    printf '%b\n' "清理指定目录（默认当前目录）及其子目录下的 LaTeX 编译辅助文件。"
    printf '\n'
    printf '%b\n' "${CYAN}选项:${RESET}"
    printf '  -h, --help    显示此帮助信息\n'
    printf '\n'
    printf '%b\n' "${CYAN}删除的文件类型:${RESET}"
    printf '  .aux .log .toc .out .bbl .blg .synctex.gz\n'
    printf '  .fdb_latexmk .fls .nav .snm .vrb .bcf .run.xml\n'
    printf '\n'
    printf '%b\n' "${CYAN}示例:${RESET}"
    printf '  %s               # 清理当前目录\n' "$(basename "$0")"
    printf '  %s ./my-note     # 清理 my-note 目录及其子目录\n' "$(basename "$0")"
    printf '  %s /path/to/note # 清理绝对路径目录\n' "$(basename "$0")"
    exit 0
}

# 解析参数
TARGET_DIR=""
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            usage
            ;;
        -*)
            printf '%b\n' "${RED}未知选项:${RESET} ${YELLOW}$arg${RESET}" >&2
            usage
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$arg"
            else
                printf '%b\n' "${RED}错误：${RESET}只能指定一个目录。" >&2
                exit 1
            fi
            ;;
    esac
done

# 若未指定目录则使用当前目录
[ -z "$TARGET_DIR" ] && TARGET_DIR="."

# 检查目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    printf '%b\n' "${RED}错误：${RESET}目录 '${YELLOW}$TARGET_DIR${RESET}' 不存在。" >&2
    exit 1
fi

# 获取绝对路径
TARGET_DIR_ABS="$(cd "$TARGET_DIR" && pwd)"

printf '%b\n' "${PURPLE}=== 清理 LaTeX 辅助文件 ===${RESET}"
printf '%b\n' "${CYAN}目标目录：${RESET}${YELLOW}$TARGET_DIR_ABS${RESET}"

# 查找并删除常见 LaTeX 辅助文件，同时打印被删除的文件路径
find "$TARGET_DIR" -type f \( \
    -name "*.aux" -o \
    -name "*.log" -o \
    -name "*.toc" -o \
    -name "*.out" -o \
    -name "*.bbl" -o \
    -name "*.blg" -o \
    -name "*.synctex.gz" -o \
    -name "*.fdb_latexmk" -o \
    -name "*.fls" -o \
    -name "*.nav" -o \
    -name "*.snm" -o \
    -name "*.vrb" -o \
    -name "*.bcf" -o \
    -name "*.run.xml" \
\) -print -delete | while read -r file; do
    printf '%b\n' "${RED}已删除: ${YELLOW}$file${RESET}"
done

printf '%b\n' "${GREEN}✓${RESET} 清理完成"