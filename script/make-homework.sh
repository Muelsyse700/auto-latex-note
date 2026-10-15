#!/bin/bash

# @description: 生成作业PDF的辅助脚本

# ===== 颜色定义 =====
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

# ===== 冲突自动解决函数（用户可自定义） =====
get_core_conflict() {
    case "$1" in
        1) echo "font-and-layout-setting-homework.tex" ;;
        2) echo "cover-or-title-setting-homework.tex" ;;
        7) echo "header-footer-setting-homework.tex" ;;
    esac
}

# ===== 统一清理函数 =====
cleanup_all() {
    # 清理后台进程
    [ -n "$CORE_PID" ] && kill "$CORE_PID" 2>/dev/null && wait "$CORE_PID" 2>/dev/null
    # 删除临时文件和目录
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    [ -n "$HOMEWORK_LIST" ] && rm -f "$HOMEWORK_LIST"
}

# ===== 帮助信息 =====
usage() {
    printf "${CYAN}用法：${RESET}\n"
    printf "  ${YELLOW}%s${RESET} <工作目录>\n" "$(basename "$0")"
    printf "\n${CYAN}选项：${RESET}\n"
    printf "  -h, --help  显示此帮助信息\n"
    printf "\n${CYAN}说明：${RESET}\n"
    printf "  在指定的工作目录下生成作业PDF。\n"
    printf "  若 homework/ 目录不存在，将询问是否自动初始化。\n"
    exit 0
}

# ===== 参数解析 =====
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

if [ "$#" -ne 1 ]; then
    printf "${RED}错误：${RESET}缺少工作目录参数\n"
    printf "用法：${YELLOW}%s${RESET} <工作目录>\n" "$(basename "$0")"
    exit 1
fi

WORK_DIR="$1"

if [ ! -d "$WORK_DIR" ]; then
    printf "${RED}错误：${RESET}工作目录不存在：${YELLOW}%s${RESET}\n" "$WORK_DIR"
    exit 1
fi

WORK_DIR="$(cd "$WORK_DIR" && pwd)"
HOMEWORK_DIR="$WORK_DIR/homework"

# ===== 若 homework/ 不存在，询问是否初始化 =====
if [ ! -d "$HOMEWORK_DIR" ]; then
    printf "${CYAN}工作目录下未找到 ${YELLOW}homework/${RESET}${CYAN} 文件夹，是否初始化创建？[Y/n] ${RESET}"
    read -r answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        printf "${YELLOW}已取消操作${RESET}\n"
        exit 0
    else
        mkdir -p "$HOMEWORK_DIR/week1"
        cat > "$HOMEWORK_DIR/week1/homework.tex" <<EOF
% 在此填写作业内容
EOF
        printf "${GREEN}已创建${RESET} ${YELLOW}homework/week1/homework.tex${RESET}\n"
        exit 0
    fi
fi

# ===== 检查 make-core.sh =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKE_CORE="$SCRIPT_DIR/make-core.sh"
if [ ! -f "$MAKE_CORE" ]; then
    printf "${RED}错误：${RESET}找不到 ${YELLOW}make-core.sh：%s${RESET}\n" "$MAKE_CORE"
    exit 1
fi
if [ ! -x "$MAKE_CORE" ]; then
    printf "${RED}错误：${RESET}${YELLOW}make-core.sh${RESET} 不可执行：${YELLOW}%s${RESET}\n" "$MAKE_CORE"
    exit 1
fi

# ===== 扫描 homework/ 下的子目录 =====
HOMEWORK_LIST="$HOMEWORK_DIR/.homework-list.$$"
find "$HOMEWORK_DIR" -mindepth 1 -maxdepth 1 -type d -print | sort > "$HOMEWORK_LIST"
trap cleanup_all EXIT

HOMEWORK_COUNT="$(wc -l < "$HOMEWORK_LIST" | tr -d ' ')"
if [ "$HOMEWORK_COUNT" -eq 0 ]; then
    printf "${RED}错误：${RESET}${YELLOW}homework/${RESET} 下没有找到作业目录\n"
    exit 1
fi

# 读取目录并计算最大名称长度
DIRS=()
MAX_LEN=0
while IFS= read -r DIR; do
    NAME="$(basename "$DIR")"
    DIRS+=("$DIR")
    LEN=${#NAME}
    [ "$LEN" -gt "$MAX_LEN" ] && MAX_LEN=$LEN
done < "$HOMEWORK_LIST"
COL_WIDTH=$((MAX_LEN + 2))

# 显示作业列表
printf "\n${PURPLE}=== 请选择作业 ===${RESET}\n\n"
INDEX=1
for DIR in "${DIRS[@]}"; do
    NAME="$(basename "$DIR")"
    printf "${PURPLE}[%d]${RESET} ${YELLOW}%-*s${RESET}\n" "$INDEX" "$COL_WIDTH" "$NAME"
    INDEX=$((INDEX + 1))
done
echo

# 选择序号
while true; do
    printf "${CYAN}请输入序号：${RESET}\n"
    read -e -r CHOICE
    case "$CHOICE" in
        ''|*[!0-9]*)
            printf "${RED}请输入有效的数字序号${RESET}\n"
            ;;
        *)
            if [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "$HOMEWORK_COUNT" ]; then
                break
            fi
            printf "${RED}序号超出范围，请重新输入${RESET}\n"
            ;;
    esac
done

SELECTED_DIR="${DIRS[$((CHOICE - 1))]}"
SELECTED_NAME="$(basename "$SELECTED_DIR")"

if ! cd "$SELECTED_DIR"; then
    printf "${RED}错误：${RESET}无法进入作业目录：${YELLOW}%s${RESET}\n" "$SELECTED_DIR"
    exit 1
fi

printf "\n${GREEN}已选择：${RESET}${YELLOW}%s${RESET}\n" "$SELECTED_NAME"
printf "${CYAN}当前目录：${RESET}${YELLOW}%s${RESET}\n\n" "$PWD"

# ===== 调用 make-core.sh --auto =====
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/make-homework.XXXXXX")"

CORE_INPUT="$TEMP_DIR/core-input"
CORE_OUTPUT="$TEMP_DIR/core-output"
mkfifo "$CORE_INPUT"
mkfifo "$CORE_OUTPUT"

"$MAKE_CORE" --auto "$SELECTED_DIR" < "$CORE_INPUT" > "$CORE_OUTPUT" &
CORE_PID=$!

exec 3> "$CORE_INPUT"
exec 4< "$CORE_OUTPUT"

while IFS= read -r LINE <&4; do
    printf '%s\n' "$LINE"
    case "$LINE" in
        "@CONFLICT order="*)
            ORDER="${LINE#@CONFLICT order=}"
            CONFLICT_FILE="$(get_core_conflict "$ORDER")"
            if [ $? -eq 0 ] && [ -n "$CONFLICT_FILE" ]; then
                printf "${GREEN}[AUTO]${RESET} order=%s -> ${YELLOW}%s${RESET}\n" "$ORDER" "$CONFLICT_FILE"
                printf '%s\n' "$CONFLICT_FILE" >&3
            else
                printf "${CYAN}请手动输入文件名：${RESET}\n"
                read -e -r MANUAL_FILE
                printf '%s\n' "$MANUAL_FILE" >&3
            fi
            ;;
    esac
done

exec 3>&-
exec 4<&-
wait "$CORE_PID"
CORE_STATUS=$?
CORE_PID=""

if [ "$CORE_STATUS" -ne 0 ]; then
    printf "\n${RED}错误：${RESET}${YELLOW}make-core.sh${RESET} 执行失败，${YELLOW}make-homework.sh${RESET} 停止\n"
    exit "$CORE_STATUS"
fi

if [ ! -f "$SELECTED_DIR/core-setting.tex" ]; then
    printf "\n${RED}错误：${RESET}${YELLOW}make-core.sh${RESET} 正常结束，但未找到 ${YELLOW}core-setting.tex${RESET}\n"
    exit 1
fi

printf "\n${GREEN}✓${RESET} ${YELLOW}core-setting.tex${RESET} 已生成\n"
printf "  ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/core-setting.tex"

# ===== 第二阶段：收集信息，生成 make.tex =====
printf "\n${PURPLE}=== 输入有关信息 ===${RESET}\n"

# 课程名称
COURSE_NAME=""
MAIN_NOTE="$WORK_DIR/main-note.tex"
if [ -f "$MAIN_NOTE" ]; then
    COURSE_NAME=$(grep -E '^\\covertitle\{[^}]*\}' "$MAIN_NOTE" | head -1 | sed -E 's/^\\covertitle\{([^}]*)\}/\1/')
fi
if [ -z "$COURSE_NAME" ]; then
    printf "${CYAN}未从 ${YELLOW}main-note.tex${RESET}${CYAN} 中找到 \\covertitle，请输入课程名称：${RESET}\n"
    read -e -r COURSE_NAME
fi

# ===== 从 homework.tex 前5行读取 @week 和 @ps =====
WEEK=""
PS_NOTE=""
HOMEWORK_TEX="$SELECTED_DIR/homework.tex"
if [ -f "$HOMEWORK_TEX" ]; then
    HEAD_5=$(head -n 5 "$HOMEWORK_TEX" 2>/dev/null)
    if [ -n "$HEAD_5" ]; then
        # 提取 @week
        WEEK_LINE=$(printf '%s\n' "$HEAD_5" | grep -E '^% @week[[:space:]]+[0-9]+' | head -n 1)
        if [ -n "$WEEK_LINE" ]; then
            WEEK=$(printf '%s\n' "$WEEK_LINE" | sed -E 's/^% @week[[:space:]]+([0-9]+).*/\1/')
        fi
        # 提取 @ps
        PS_LINE=$(printf '%s\n' "$HEAD_5" | grep -E '^% @ps[[:space:]]+' | head -n 1)
        if [ -n "$PS_LINE" ]; then
            PS_NOTE=$(printf '%s\n' "$PS_LINE" | sed -E 's/^% @ps[[:space:]]+//')
        fi
    fi
fi

# 周次（若 homework.tex 中未指定，则沿用原有逻辑）
if [ -z "$WEEK" ]; then
    if [[ "$SELECTED_NAME" =~ week([0-9]+) ]]; then
        WEEK="${BASH_REMATCH[1]}"
    fi
fi
if [ -z "$WEEK" ]; then
    printf "${CYAN}未从 ${YELLOW}homework.tex${RESET}${CYAN} 或目录名中解析出周次，请输入周次(数字)：${RESET}\n"
    read -e -r WEEK
fi

# 姓名与学号
printf "${CYAN}请输入学生姓名：${RESET}\n"
read -e -r STUDENT_NAME
printf "${CYAN}请输入学号：${RESET}\n"
read -e -r STUDENT_ID

# 生成 make.tex
PS_BLOCK=""
if [ -n "$PS_NOTE" ]; then
    PS_BLOCK="\\vspace{-1em}\\noindent{\\scriptsize\\textit{注：$PS_NOTE}}
"
fi

cat > make.tex <<EOF
\documentclass[a4paper,twoside,12pt,fontset=none,UTF8]{ctexart}
\input{core-setting.tex}
\graphicspath{{figure/}}
\coursename{$COURSE_NAME}
\week{$WEEK}
\studentname{$STUDENT_NAME}
\studentid{$STUDENT_ID}
\schoollogo{logo.pdf}
\begin{document}
\maketitle
${PS_BLOCK}\input{homework.tex}
\end{document}
EOF

printf "\n${GREEN}✓${RESET} ${YELLOW}make.tex${RESET} 已生成 ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/make.tex"

LOGO_SRC="$SCRIPT_DIR/../template/logo/logo.pdf"
if [ -f "$LOGO_SRC" ]; then
    cp "$LOGO_SRC" "$SELECTED_DIR/"
    printf "${GREEN}✓${RESET} ${YELLOW}logo.pdf${RESET} 已复制 ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/"
else
    printf "${YELLOW}警告：${RESET}未找到 ${YELLOW}%s${RESET}，请手动将 ${YELLOW}logo.pdf${RESET} 放入 ${YELLOW}%s${RESET}\n" "$LOGO_SRC" "$SELECTED_DIR/"
fi


# ===== 第三阶段：编译 make.tex → PDF =====
printf "\n${PURPLE}=== 正在编译 ===${RESET}\n"

cd "$SELECTED_DIR" || exit 1

PDF_NAME="homework-week${WEEK}.pdf"

# 用系统默认 PDF 阅读器打开
open_pdf() {
    local pdf="$1"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$pdf" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then
        open "$pdf" >/dev/null 2>&1 &
    elif command -v wslview >/dev/null 2>&1; then
        wslview "$pdf" >/dev/null 2>&1 &
    elif command -v cygstart >/dev/null 2>&1; then
        cygstart "$pdf" >/dev/null 2>&1 &
    else
        printf "${YELLOW}未找到系统默认 PDF 打开命令，请手动打开：%s${RESET}\n" "$pdf"
    fi
}

compile_once() {
    local label="$1"
    printf "${CYAN}%s...${RESET}" "$label"
    if xelatex -interaction=nonstopmode make.tex > /dev/null 2>&1; then
        printf "${GREEN}完成${RESET}\n"
        return 0
    else
        printf "${RED}失败${RESET}\n"
        printf "${RED}错误：${RESET}xelatex 编译失败\n"
        return 1
    fi
}

# 收尾：重命名最终 PDF 并清理辅助文件
finalize_output() {
    if [ ! -f "make.pdf" ]; then
        printf "${RED}错误：${RESET}未找到 ${YELLOW}make.pdf${RESET}\n"
        return 1
    fi

    mv -f "make.pdf" "$PDF_NAME"
    rm -f make.tex make.aux make.log make.out core-setting.tex logo.pdf

    printf "\n${GREEN}✓${RESET} PDF 已生成 ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/$PDF_NAME"
    return 0
}

# 初始编译两次
for i in 1 2; do
    compile_once "第 ${i} 次编译" || exit 1
done

if [ ! -f "make.pdf" ]; then
    printf "${RED}错误：${RESET}未找到 ${YELLOW}make.pdf${RESET}\n"
    exit 1
fi

while true; do
    printf "\n${CYAN}请选择下一步操作：${RESET}\n"
    printf "${PURPLE}[1]${RESET} 查看编译结果\n"
    printf "${PURPLE}[2]${RESET} 再编译一次\n"
    printf "${PURPLE}[3]${RESET} 打印\n"
    printf "${PURPLE}[q]${RESET} 退出\n"
    printf "${CYAN}请输入序号 [1/2/3/q]：${RESET}"

    read -e -r ACTION

    case "$ACTION" in
        1)
            if [ ! -f "make.pdf" ]; then
                printf "${RED}错误：${RESET}未找到 ${YELLOW}make.pdf${RESET}\n"
                continue
            fi
            open_pdf "$SELECTED_DIR/make.pdf"
            ;;
        2)
            compile_once "再编译一次" || exit 1
            ;;
        3)
            finalize_output || exit 1

            AUTO_PRINT="$SCRIPT_DIR/auto-print.sh"
            if [ ! -f "$AUTO_PRINT" ]; then
                printf "${RED}错误：${RESET}找不到 ${YELLOW}auto-print.sh${RESET}：${YELLOW}%s${RESET}\n" "$AUTO_PRINT"
                exit 1
            fi

            printf "${CYAN}正在调用打印脚本...${RESET}\n"
            if [ -x "$AUTO_PRINT" ]; then
                "$AUTO_PRINT" "$SELECTED_DIR" "$PDF_NAME"
            else
                zsh "$AUTO_PRINT" "$SELECTED_DIR" "$PDF_NAME"
            fi
            exit 0
            ;;
        q|Q)
            finalize_output || exit 1
            printf "${YELLOW}已退出${RESET}\n"
            exit 0
            ;;
        *)
            printf "${RED}请输入 1、2、3 或 q${RESET}\n"
            ;;
    esac
done
