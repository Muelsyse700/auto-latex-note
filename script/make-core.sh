#!/bin/bash

# @description: 将模板设置文件合并生成 core-setting.tex 文件

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

usage(){
    printf "%b\n" "${CYAN}用法:${RESET} $0 [目标目录]"
    printf "%b\n" "生成 setting/core-setting.tex"
    exit 0
}

[ "$1" = "-h" ] || [ "$1" = "--help" ] && usage

TARGET_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../template"

mkdir -p "$TARGET_DIR/setting" || exit 1
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
OUTPUT="$TARGET_DIR/setting/core-setting.tex"

declare -a FILES ORDERS DESCRIPTIONS SELECTED
index=0

for file in "$TEMPLATE"/*.tex; do
    [ -f "$file" ] || continue
    order=$(grep -m1 '^% @order:' "$file" | sed 's/.*@order:[ ]*//')
    [ -n "$order" ] || continue
    desc=$(grep -m1 '^% @description:' "$file" | sed 's/.*@description:[ ]*//')
    FILES[$index]="$file"
    ORDERS[$index]="$order"
    DESCRIPTIONS[$index]="$desc"
    index=$((index+1))
done

[ "$index" -eq 0 ] && {
    printf "${RED}未找到有效模块${RESET}\n"
    exit 1
}

declare -a SORTED
while read -r idx; do
    SORTED+=("$idx")
done < <(
    for i in "${!FILES[@]}"; do
        printf '%s %s\n' "${ORDERS[$i]}" "$i"
    done | sort -n | awk '{print $2}'
)

declare -a OLD_ORDERS

if [ -f "$OUTPUT" ]; then
    while read -r order; do
        OLD_ORDERS+=("$order")
    done < <(grep '^% @order:' "$OUTPUT" | sed 's/.*@order:[ ]*//')

    if [ "${#OLD_ORDERS[@]}" -gt 0 ]; then
        printf "\n${GREEN}>>> 检测到已有配置 >>>${RESET}\n"

        for o in "${OLD_ORDERS[@]}"; do
            for i in "${SORTED[@]}"; do
                if [ "${ORDERS[$i]}" = "$o" ]; then
                    printf "${GREEN}✓${RESET} ${YELLOW}%s${RESET} ${CYAN}[%s]${RESET}\n" \
                        "$(basename "${FILES[$i]}")" "$o"
                fi
            done
        done

        for o in "${OLD_ORDERS[@]}"; do
            found=0
            for i in "${SORTED[@]}"; do
                [ "${ORDERS[$i]}" = "$o" ] && found=1
            done
            [ "$found" -eq 0 ] &&
                printf "${RED}! 消失模块 order=%s${RESET}\n" "$o"
        done

        printf "是否使用上一次配置?[Y/n] "
        read -r reuse

        if [[ ! "$reuse" =~ ^[Nn]$ ]]; then
            for o in "${OLD_ORDERS[@]}"; do
                for i in "${SORTED[@]}"; do
                    [ "${ORDERS[$i]}" = "$o" ] && SELECTED+=("$i")
                done
            done
        fi
    fi
fi

print_module(){
    local num=$1
    local i=$2
    printf "${PURPLE}[%s]${RESET} ${YELLOW}%s${RESET} ${CYAN}(%s)${RESET}\n" \
        "$num" "$(basename "${FILES[$i]}")" "${ORDERS[$i]}"
}

if [ "${#SELECTED[@]}" -eq 0 ]; then
    printf "\n${CYAN}=== 必要模块 ===${RESET}\n"
    num=1
    for i in "${SORTED[@]}"; do
        if [ "${ORDERS[$i]}" -lt 20 ]; then
            SELECTED+=("$i")
            print_module "$num" "$i"
            num=$((num+1))
        fi
    done

    declare -a REC
    for i in "${SORTED[@]}"; do
        if [ "${ORDERS[$i]}" -ge 20 ] && [ "${ORDERS[$i]}" -lt 100 ]; then
            REC+=("$i")
        fi
    done

    if [ "${#REC[@]}" -gt 0 ]; then
        printf "\n${CYAN}=== 推荐模块 ===${RESET}\n"
        num=1
        for i in "${REC[@]}"; do
            print_module "$num" "$i"
            num=$((num+1))
        done

        printf "是否启用全部推荐模块?[Y/n] "
        read -r ans

        if [[ ! "$ans" =~ ^[Nn]$ ]]; then
            SELECTED+=("${REC[@]}")
        else
            printf "输入取消编号："
            read -r remove
            num=1
            for i in "${REC[@]}"; do
                skip=0
                for r in $remove; do
                    [ "$r" = "$num" ] && skip=1
                done
                [ "$skip" -eq 0 ] && SELECTED+=("$i")
                num=$((num+1))
            done
        fi
    fi

    declare -a OPT
    for i in "${SORTED[@]}"; do
        if [ "${ORDERS[$i]}" -ge 100 ]; then
            OPT+=("$i")
        fi
    done

    if [ "${#OPT[@]}" -gt 0 ]; then
        printf "\n${CYAN}=== 自选模块 ===${RESET}\n"
        num=1
        for i in "${OPT[@]}"; do
            print_module "$num" "$i"
            num=$((num+1))
        done

        printf "输入需要加入编号："
        read -r add

        for r in $add; do
            i=$((r-1))
            [ "$i" -ge 0 ] && [ "$i" -lt "${#OPT[@]}" ] &&
                SELECTED+=("${OPT[$i]}")
        done
    fi
fi

declare -a FINAL

while read -r idx; do
    FINAL+=("$idx")
done < <(
    for i in "${SELECTED[@]}"; do
        echo "${ORDERS[$i]} $i"
    done | sort -n | awk '{print $2}'
)

printf "\n${CYAN}=== 确认要加入的模块 ===${RESET}\n"

printf "\n${GREEN}>>> 必要模块 >>>${RESET}\n"
num=1
for i in "${FINAL[@]}"; do
    if [ "${ORDERS[$i]}" -lt 20 ]; then
        print_module "$num" "$i"
        num=$((num+1))
    fi
done

printf "\n${GREEN}>>> 推荐模块 >>>${RESET}\n"
num=1
for i in "${FINAL[@]}"; do
    if [ "${ORDERS[$i]}" -ge 20 ] && [ "${ORDERS[$i]}" -lt 100 ]; then
        print_module "$num" "$i"
        num=$((num+1))
    fi
done

printf "\n${GREEN}>>> 自选模块 >>>${RESET}\n"
num=1
for i in "${FINAL[@]}"; do
    if [ "${ORDERS[$i]}" -ge 100 ]; then
        print_module "$num" "$i"
        num=$((num+1))
    fi
done

printf "\n确认生成?[Y/n] "
read -r confirm
[[ "$confirm" =~ ^[Nn]$ ]] && exit 0

{
    printf "%% @name: core-setting\n"
    printf "%% @description: 自动生成的LaTeX设置文件\n\n"
    for i in "${FINAL[@]}"; do
        printf "%% !%s\n\n" "${DESCRIPTIONS[$i]}"
        cat "${FILES[$i]}"
        printf "\n\n"
    done
} > "$OUTPUT"

printf "\n${GREEN}✓ 已生成${RESET} ${YELLOW}%s${RESET}\n" "$OUTPUT"