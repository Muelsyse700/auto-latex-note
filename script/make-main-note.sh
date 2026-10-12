#!/bin/bash

# @description*: 向用户请求信息生成main-note.tex文件

RESET=$'\033[0m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'

# 帮助信息
usage() {
    printf '%b\n' "${CYAN}用法:${RESET} $0 [目标目录]"
    printf '%b\n' ""
    printf '%b\n' "从模板生成主笔记文件 ${YELLOW}main-note.tex${RESET}。"
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../template/main-note.tex"

mkdir -p "$TARGET_DIR" || {
    printf "${RED}错误：无法创建目录 $TARGET_DIR${RESET}\n" >&2
    exit 1
}

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
OUTPUT="$TARGET_DIR/main-note.tex"

if [ ! -f "$TEMPLATE" ]; then
    printf "${RED}错误：找不到模板文件：$TEMPLATE${RESET}\n" >&2
    exit 1
fi

get_value() {
    local command="$1"
    local line
    local regex

    line="$(grep -m 1 "\\\\${command}{" "$TEMPLATE")"
    regex="^[[:space:]]*\\\\${command}[[:space:]]*\{(.*)\}[[:space:]]*$"

    if [[ "$line" =~ $regex ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    fi
}

ask_value() {
    local name="$1"
    local default="$2"
    local input
    local prompt
    if [ -n "$default" ]; then
        prompt="${CYAN}${name}${RESET} ${YELLOW}[${default}]${RESET}： "
    else
        prompt="${CYAN}${name}${RESET}： "
    fi
    read -e -r -p "$prompt" input
    if [ -n "$input" ]; then
        printf '%s' "$input"
    else
        printf '%s' "$default"
    fi
}

TITLE="$(get_value "covertitle")"
ENGLISH_TITLE="$(get_value "coverengtitle")"
AUTHOR="$(get_value "coverauthor")"
DATE="$(get_value "coverdate")"
GITHUB="$(get_value "covergithub")"
ORCID="$(get_value "coverorcid")"

if [ -z "$DATE" ]; then
    DATE="$(date '+%Y-%m-%d')"
fi

echo
printf "${CYAN}=== 输入 main-note.tex 文件基本信息 ===${RESET}\n"
echo

TITLE="$(ask_value "笔记标题" "$TITLE")"
ENGLISH_TITLE="$(ask_value "英文标题" "$ENGLISH_TITLE")"
AUTHOR="$(ask_value "作者" "$AUTHOR")"
DATE="$(ask_value "日期" "$DATE")"
GITHUB="$(ask_value "GitHub" "$GITHUB")"
ORCID="$(ask_value "ORCID" "$ORCID")"

echo

awk \
    -v title="$TITLE" \
    -v english_title="$ENGLISH_TITLE" \
    -v author="$AUTHOR" \
    -v date="$DATE" \
    -v github="$GITHUB" \
    -v orcid="$ORCID" '
    /^[[:space:]]*\\covertitle[[:space:]]*\{/ {
        print "\\covertitle{" title "}"
        next
    }

    /^[[:space:]]*\\coverengtitle[[:space:]]*\{/ {
        print "\\coverengtitle{" english_title "}"
        next
    }

    /^[[:space:]]*\\coverauthor[[:space:]]*\{/ {
        print "\\coverauthor{" author "}"
        next
    }

    /^[[:space:]]*\\coverdate[[:space:]]*\{/ {
        print "\\coverdate{" date "}"
        next
    }

    /^[[:space:]]*\\covergithub[[:space:]]*\{/ {
        print "\\covergithub{" github "}"
        next
    }

    /^[[:space:]]*\\coverorcid[[:space:]]*\{/ {
        print "\\coverorcid{" orcid "}"
        next
    }

    {
        print
    }
' "$TEMPLATE" > "$OUTPUT"

printf "${GREEN}✓ 已生成 ${YELLOW}%s${RESET}\n" "$OUTPUT"
