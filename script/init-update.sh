#!/bin/bash

# @description: 初始化或更新 latexNote 笔记目录

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../template"

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'

usage() {
    printf '%b\n' "${CYAN}用法:${RESET} $(basename "$0") [选项] [目标目录]"
    printf '%b\n' "在当前目录（或指定目录）初始化或更新一个 latexNote 笔记项目。"
    printf '\n'
    printf '%b\n' "${CYAN}选项:${RESET}"
    printf '  -h, --help       显示此帮助信息\n'
    printf '  -u, --update     更新 setting 目录下的模板文件(cover.pdf, settings.json, .gitignore)\n'
    printf '                   重新生成 setting/latexNote.sty。\n'
    printf '\n'
    printf '%b\n' "${CYAN}初始化时创建的结构:${RESET}"
    printf '  main-note.tex\n'
    printf '  table/\n'
    printf '    Input/\n'
    printf '    Output/\n'
    printf '    tables-index.txt\n'
    printf '  figure/\n'
    printf '  chapter/\n'
    printf '    chapter1.tex\n'
    printf '  setting/\n'
    printf '    latexNote.sty\n'
    printf '    cover.pdf\n'
    printf '  reference/\n'
    printf '  .vscode/\n'
    printf '    settings.json\n'
    printf '  .gitignore\n'
    printf '  .git/\n'
    printf '\n'
    printf '%b\n' "${CYAN}示例:${RESET}"
    printf '  %s                # 在当前目录初始化\n' "$(basename "$0")"
    printf '  %s my-note        # 在 my-note 目录初始化\n' "$(basename "$0")"
    printf '  %s -u             # 在当前目录执行更新\n' "$(basename "$0")"
    printf '  %s --update my-note # 在 my-note 目录执行更新\n' "$(basename "$0")"
    exit 0
}

# 解析命令行参数
UPDATE_MODE=false
TARGET_DIR=""
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -u|--update)
            UPDATE_MODE=true
            ;;
        -*)
            printf '%b\n' "${RED}未知选项: $1${RESET}" >&2
            usage
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            else
                printf '%b\n' "${RED}错误：只能指定一个目标目录。${RESET}" >&2
                exit 1
            fi
            ;;
    esac
    shift
done

# 若未指定目录，则使用当前目录
TARGET_DIR="${TARGET_DIR:-.}"
mkdir -p "$TARGET_DIR"
TARGET_DIR_ABS="$(cd "$TARGET_DIR" && pwd)"

set -e

# -------------------- 更新模式 --------------------
if [ "$UPDATE_MODE" = true ]; then
    printf '%b\n' "${CYAN}=== latexNote 更新模式 ===${RESET}"
    printf '目标目录：%s\n\n' "$TARGET_DIR_ABS"

    # 确保必要的子目录存在
    mkdir -p "$TARGET_DIR/setting" "$TARGET_DIR/.vscode"

    # 复制模板文件（覆盖）
    if [ ! -f "$TEMPLATE_DIR/cover.pdf" ]; then
        printf '%b\n' "${RED}错误：找不到模板文件：$TEMPLATE_DIR/cover.pdf${RESET}"
        exit 1
    fi
    cp "$TEMPLATE_DIR/cover.pdf" "$TARGET_DIR/setting/cover.pdf"
    printf '%b\n' "${GREEN}✓ 已更新 ${YELLOW}setting/cover.pdf${RESET}"

    if [ ! -f "$TEMPLATE_DIR/settings.json" ]; then
        printf '%b\n' "${RED}错误：找不到模板文件：$TEMPLATE_DIR/settings.json${RESET}"
        exit 1
    fi
    cp "$TEMPLATE_DIR/settings.json" "$TARGET_DIR/.vscode/settings.json"
    printf '%b\n' "${GREEN}✓ 已更新 ${YELLOW}.vscode/settings.json${RESET}"

    if [ ! -f "$TEMPLATE_DIR/note.gitignore" ]; then
        printf '%b\n' "${RED}错误：找不到模板文件：$TEMPLATE_DIR/note.gitignore${RESET}"
        exit 1
    fi

    cp "$TEMPLATE_DIR/note.gitignore" "$TARGET_DIR/.gitignore"
    printf '%b\n' "${GREEN}✓ 已更新 ${YELLOW}.gitignore${RESET}"

    # 重新生成 latexNote.sty
    printf '%b\n' "${CYAN}正在重新生成 setting/core-setting.tex ...${RESET}"
    "$SCRIPT_DIR/make-core.sh" "$TARGET_DIR"
    printf '%b\n' "${GREEN}✓ 已更新 ${YELLOW}setting/core-setting.tex${RESET}"

    printf '\n'
    printf '%b\n' "${CYAN}=== auto-latex-note 更新完成 ===${RESET}"
    printf '%b\n' "${YELLOW}提示：若需更新 main-note.tex 中的内容，请手动调整。${RESET}"
    exit 0
fi

# -------------------- 初始化模式 --------------------
printf '%b\n' "${CYAN}=== latexNote 初始化 ===${RESET}"
printf '目标目录：%s\n\n' "$TARGET_DIR_ABS"

if ! command -v git >/dev/null 2>&1; then
    printf '%b\n' "${RED}错误：未找到 Git，请先安装 Git。${RESET}"
    exit 1
fi

mkdir -p \
    "$TARGET_DIR/table/Input" \
    "$TARGET_DIR/table/Output" \
    "$TARGET_DIR/figure" \
    "$TARGET_DIR/chapter" \
    "$TARGET_DIR/setting" \
    "$TARGET_DIR/reference" \
    "$TARGET_DIR/.vscode"

printf '%b\n' "${GREEN}✓ 已创建目录结构${RESET}"

"$SCRIPT_DIR/make-main-note.sh" "$TARGET_DIR"

"$SCRIPT_DIR/make-core.sh" "$TARGET_DIR"

if [ ! -f "$TEMPLATE_DIR/cover.pdf" ]; then
    printf '%b\n' "${RED}错误：找不到模板文件：$TEMPLATE_DIR/cover.pdf${RESET}"
    exit 1
fi
cp "$TEMPLATE_DIR/cover.pdf" "$TARGET_DIR/setting/cover.pdf"

if [ ! -f "$TEMPLATE_DIR/settings.json" ]; then
    printf '%b\n' "${RED}错误：找不到模板文件：$TEMPLATE_DIR/settings.json${RESET}"
    exit 1
fi
cp "$TEMPLATE_DIR/settings.json" "$TARGET_DIR/.vscode/settings.json"

if [ ! -f "$TEMPLATE_DIR/note.gitignore" ]; then
    printf '%b\n' "${RED}错误：找不到模板文件：$TEMPLATE_DIR/note.gitignore${RESET}"
    exit 1
fi
cp "$TEMPLATE_DIR/note.gitignore" "$TARGET_DIR/.gitignore"

touch "$TARGET_DIR/table/table-index.txt"
printf '%b\n' "${GREEN}✓ 已创建 ${YELLOW}table/table-index.txt${RESET}"
touch "$TARGET_DIR/chapter/chapter1.tex"
printf '%b\n' "${GREEN}✓ 已创建 ${YELLOW}chapter/chapter1.tex${RESET}"
printf '%b\n' "${GREEN}✓ 已复制 ${YELLOW}.vscode/settings.json${RESET}"
printf '%b\n' "${GREEN}✓ 已复制 ${YELLOW}.gitignore${RESET}"

git -C "$TARGET_DIR" init -b main
printf '%b\n' "${GREEN}✓ Git 仓库初始化完成${RESET}"

git -C "$TARGET_DIR" add .
git -C "$TARGET_DIR" commit -m "Initial commit"
printf '%b\n' "${GREEN}✓ 已提交 Initial commit${RESET}"

printf '\n'
printf '%b\n' "${CYAN}=== auto-latex-note 初始化完成 ===${RESET}"
printf '%b\n' "${YELLOW}提示：首次编译请使用 XeLaTeX*2${RESET}"