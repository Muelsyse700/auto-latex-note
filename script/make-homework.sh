#!/bin/bash

# @description: 生成作业PDF的辅助脚本

# ===== 颜色定义 =====
RESET='\033[0m'
BOLD='\033[1m'
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
    printf "  %s <工作目录>\n" "$(basename "$0")"
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
    printf "用法：%s <工作目录>\n" "$(basename "$0")"
    exit 1
fi

WORK_DIR="$1"

if [ ! -d "$WORK_DIR" ]; then
    printf "${RED}错误：${RESET}工作目录不存在：%s\n" "$WORK_DIR"
    exit 1
fi

WORK_DIR="$(cd "$WORK_DIR" && pwd)"
HOMEWORK_DIR="$WORK_DIR/homework"

# ===== 若 homework/ 不存在，询问是否初始化 =====
if [ ! -d "$HOMEWORK_DIR" ]; then
    printf "${YELLOW}工作目录下未找到 homework/ 文件夹，是否初始化创建？[Y/n] ${RESET}"
    read -r answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        printf "${YELLOW}已取消操作${RESET}\n"
        exit 0
    else
        mkdir -p "$HOMEWORK_DIR/week1"
        cat > "$HOMEWORK_DIR/week1/homework.tex" <<EOF
% 在此填写作业内容
EOF
        printf "${GREEN}已创建 homework/week1/homework.tex${RESET}\n"
        exit 0
    fi
fi

# ===== 检查 make-core.sh =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKE_CORE="$SCRIPT_DIR/make-core.sh"
if [ ! -f "$MAKE_CORE" ]; then
    printf "${RED}错误：${RESET}找不到 make-core.sh：%s\n" "$MAKE_CORE"
    exit 1
fi
if [ ! -x "$MAKE_CORE" ]; then
    printf "${RED}错误：${RESET}make-core.sh 不可执行：%s\n" "$MAKE_CORE"
    exit 1
fi

# ===== 扫描 homework/ 下的子目录 =====
HOMEWORK_LIST="$HOMEWORK_DIR/.homework-list.$$"
find "$HOMEWORK_DIR" -mindepth 1 -maxdepth 1 -type d -print | sort > "$HOMEWORK_LIST"
trap cleanup_all EXIT

HOMEWORK_COUNT="$(wc -l < "$HOMEWORK_LIST" | tr -d ' ')"
if [ "$HOMEWORK_COUNT" -eq 0 ]; then
    printf "${RED}错误：${RESET}homework/ 下没有找到作业目录\n"
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
printf "\n${CYAN}=== 请选择作业 ===${RESET}\n\n"
INDEX=1
for DIR in "${DIRS[@]}"; do
    NAME="$(basename "$DIR")"
    printf "${PURPLE}[%d]${RESET} ${YELLOW}%-*s${RESET}\n" "$INDEX" "$COL_WIDTH" "$NAME"
    INDEX=$((INDEX + 1))
done
echo

# 选择序号
while true; do
    printf "${CYAN}请输入序号：${RESET}"
    read -r CHOICE
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
    printf "${RED}错误：${RESET}无法进入作业目录：%s\n" "$SELECTED_DIR"
    exit 1
fi

printf "\n${GREEN}已选择：${RESET}${YELLOW}%s${RESET}\n" "$SELECTED_NAME"
printf "${CYAN}当前目录：${RESET}%s\n\n" "$PWD"

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
                printf "${GREEN}[AUTO]${RESET} order=%s -> %s\n" "$ORDER" "$CONFLICT_FILE"
                printf '%s\n' "$CONFLICT_FILE" >&3
            else
                printf "${YELLOW}请手动输入文件名：${RESET}"
                read -r MANUAL_FILE
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
    printf "\n${RED}错误：${RESET}make-core.sh 执行失败，make-homework.sh 停止\n"
    exit "$CORE_STATUS"
fi

if [ ! -f "$SELECTED_DIR/core-setting.tex" ]; then
    printf "\n${RED}错误：${RESET}make-core.sh 正常结束，但未找到 core-setting.tex\n"
    exit 1
fi

printf "\n${GREEN}✓${RESET} core-setting.tex 已生成\n"
printf "  ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/core-setting.tex"

# ===== 第二阶段：收集信息，生成 make.tex =====
printf "\n${CYAN}=== 输入有关信息 ===${RESET}\n"

# 课程名称
COURSE_NAME=""
MAIN_NOTE="$WORK_DIR/main-note.tex"
if [ -f "$MAIN_NOTE" ]; then
    COURSE_NAME=$(grep -E '^\\covertitle\{[^}]*\}' "$MAIN_NOTE" | head -1 | sed -E 's/^\\covertitle\{([^}]*)\}/\1/')
fi
if [ -z "$COURSE_NAME" ]; then
    printf "${CYAN}未从 main-note.tex 中找到 \\covertitle，请输入课程名称：${RESET}"
    read -r COURSE_NAME
fi

# 周次
WEEK=""
if [[ "$SELECTED_NAME" =~ week([0-9]+) ]]; then
    WEEK="${BASH_REMATCH[1]}"
fi
if [ -z "$WEEK" ]; then
    printf "${CYAN}未从目录名中解析出周次，请输入周次(数字)：${RESET}"
    read -r WEEK
fi

# 姓名与学号
printf "${CYAN}请输入学生姓名：${RESET}"
read -r STUDENT_NAME
printf "${CYAN}请输入学号：${RESET}"
read -r STUDENT_ID

# 生成 make.tex
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
\input{homework.tex}
\end{document}
EOF

printf "\n${GREEN}✓${RESET} make.tex 已生成 ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/make.tex"

LOGO_SRC="$SCRIPT_DIR/../template/logo/logo.pdf"
if [ -f "$LOGO_SRC" ]; then
    cp "$LOGO_SRC" "$SELECTED_DIR/"
    printf "${GREEN}✓${RESET} logo.pdf 已复制 ${YELLOW}%s${RESET}\n" "$SELECTED_DIR/"
else
    printf "${YELLOW}警告：${RESET}未找到 ${YELLOW}%s${RESET}，请手动将 logo.pdf 放入 ${YELLOW}%s${RESET}\n" "$LOGO_SRC" "$SELECTED_DIR/"
fi


# ===== 第三阶段：编译 make.tex → PDF =====
printf "\n${CYAN}=== 正在编译 ===${RESET}\n"

cd "$SELECTED_DIR" || exit 1

for i in 1 2; do
    printf "第 %d 次编译..." "$i"
    if xelatex -interaction=nonstopmode make.tex > /dev/null 2>&1; then
        printf "${GREEN}完成${RESET}\n"
    else
        printf "${RED}失败${RESET}\n"
        printf "${RED}错误：${RESET}xelatex 编译失败\n"
        exit 1
    fi
done

if [ ! -f "make.pdf" ]; then
    printf "${RED}错误：${RESET}未找到 make.pdf\n"
    exit 1
fi

PDF_NAME="homework-week${WEEK}.pdf"
mv "make.pdf" "$PDF_NAME"
rm -f make.tex make.aux make.log make.out core-setting.tex logo.pdf

printf "\n${GREEN}✓ PDF 已生成：${RESET}${YELLOW}%s${RESET}\n" "$SELECTED_DIR/$PDF_NAME"

exit 0