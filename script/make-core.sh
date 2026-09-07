#!/bin/bash

# @description: 将模板设置文件合并生成 core-setting.tex 文件

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

# 全局标志
AUTO_MODE=0
TARGET_DIR=""

usage() {
    if [ $AUTO_MODE -eq 0 ]; then
        printf "%b\n" "${CYAN}用法:${RESET} $0 [目标目录]"
        printf "%b\n" "生成 core-setting.tex 到目标目录"
        printf "%b\n" "或: $0 --auto <目标目录>  (机器自动化模式)"
    else
        # 机器模式下不输出人类友好信息，直接退出
        exit 1
    fi
    exit 0
}

# 输出错误信息（人类模式彩色，机器模式无颜色且可能输出到stderr）
error_exit() {
    local msg="$1"
    if [ $AUTO_MODE -eq 0 ]; then
        printf "${RED}错误:${RESET} %s\n" "$msg" >&2
    else
        echo "ERROR: $msg" >&2
    fi
    exit 1
}

# 解析参数
if [ "$1" = "--auto" ]; then
    AUTO_MODE=1
    shift
    if [ -z "$1" ]; then
        echo "ERROR: --auto 需要指定目标目录" >&2
        exit 1
    fi
    TARGET_DIR="$1"
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
else
    TARGET_DIR="${1:-.}"
fi

# 如果未设置目标目录（人类模式无参数时），已设置
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../template"

# 创建目标目录
mkdir -p "$TARGET_DIR" || exit 1
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
OUTPUT="$TARGET_DIR/core-setting.tex"
SETTING_OUTPUT="$TARGET_DIR/setting/core-setting.tex"

# 扫描模板文件
declare -a FILES ORDERS DESCRIPTIONS
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

[ "$index" -eq 0 ] && error_exit "未找到有效模块"

# 按 order 排序（稳定）
declare -a SORTED
while read -r idx; do
    SORTED+=("$idx")
done < <(
    for i in "${!FILES[@]}"; do
        printf '%s %s\n' "${ORDERS[$i]}" "$i"
    done | sort -n -k1 | awk '{print $2}'
)

# 计算最大文件名长度（用于人类模式对齐）
max_len=0
for i in "${SORTED[@]}"; do
    name=$(basename "${FILES[$i]}")
    len=${#name}
    [ $len -gt $max_len ] && max_len=$len
done
col_width=$((max_len + 2))

# 打印模块信息（人类模式）
print_module() {
    local num=$1
    local i=$2
    local show_desc=$3
    local name=$(basename "${FILES[$i]}")
    printf "${PURPLE}[%d]${RESET} ${YELLOW}%-*s${RESET}${CYAN}(%d)${RESET}" \
        "$num" "$col_width" "$name" "${ORDERS[$i]}"
    if [ "$show_desc" -eq 1 ] && [ -n "${DESCRIPTIONS[$i]}" ]; then
        printf " ${GREEN}%s${RESET}" "${DESCRIPTIONS[$i]}"
    fi
    printf "\n"
}

# ---------- 通用查找函数 ----------
find_module_by_order_and_name() {
    local order="$1"
    local name="$2"
    local candidates=()
    for i in "${SORTED[@]}"; do
        if [ "${ORDERS[$i]}" = "$order" ]; then
            candidates+=("$i")
        fi
    done
    if [ ${#candidates[@]} -eq 1 ]; then
        echo "${candidates[0]}"
        return
    elif [ ${#candidates[@]} -gt 1 ] && [ -n "$name" ]; then
        for i in "${candidates[@]}"; do
            if [ "$(basename "${FILES[$i]}")" = "$name" ]; then
                echo "$i"
                return
            fi
        done
    fi
    echo "-1"
}

# ---------- 冲突处理函数（机器模式）----------
resolve_required_conflicts_auto() {
    declare -a REQ_INDICES
    for i in "${SORTED[@]}"; do
        if [ "${ORDERS[$i]}" -lt 20 ]; then
            REQ_INDICES+=("$i")
        fi
    done

    # 按 order 分组
    declare -a order_list
    for i in "${REQ_INDICES[@]}"; do
        order_list+=("${ORDERS[$i]}")
    done
    declare -a unique_orders=($(printf '%s\n' "${order_list[@]}" | sort -n -u))

    declare -a SELECTED_REQUIRED=()
    for ord in "${unique_orders[@]}"; do
        declare -a group=()
        for i in "${REQ_INDICES[@]}"; do
            if [ "${ORDERS[$i]}" -eq "$ord" ]; then
                group+=("$i")
            fi
        done
        if [ ${#group[@]} -eq 1 ]; then
            SELECTED_REQUIRED+=("${group[0]}")
        else
            # 冲突：输出 @CONFLICT order=<N>
            echo "@CONFLICT order=$ord"
            # 等待一行输入（文件名）
            read -r chosen_file
            if [ -z "$chosen_file" ]; then
                error_exit "机器模式：未收到文件名输入"
            fi
            found=0
            for g in "${group[@]}"; do
                if [ "$(basename "${FILES[$g]}")" = "$chosen_file" ]; then
                    SELECTED_REQUIRED+=("$g")
                    found=1
                    break
                fi
            done
            if [ $found -eq 0 ]; then
                error_exit "机器模式：输入的文件名 '$chosen_file' 不在冲突组中"
            fi
        fi
    done
    REQUIRED_SELECTED=("${SELECTED_REQUIRED[@]}")
}

# ---------- 主体逻辑 ----------

if [ $AUTO_MODE -eq 1 ]; then
    # 机器模式
    resolve_required_conflicts_auto

    declare -a FINAL=()
    for i in "${REQUIRED_SELECTED[@]}"; do
        FINAL+=("$i")
    done
    for i in "${SORTED[@]}"; do
        if [ "${ORDERS[$i]}" -ge 20 ] && [ "${ORDERS[$i]}" -lt 100 ]; then
            FINAL+=("$i")
        fi
    done
    declare -a FINAL_SORTED
    while read -r idx; do
        FINAL_SORTED+=("$idx")
    done < <(
        for i in "${FINAL[@]}"; do
            printf '%s %s %s\n' "${ORDERS[$i]}" "$(basename "${FILES[$i]}")" "$i"
        done | sort -n -k1 -k2 | awk '{print $3}'
    )

    {
        printf "%% @description: 自动生成的LaTeX设置文件\n\n"
        for i in "${FINAL_SORTED[@]}"; do
            printf "%% @name: %s\n" "$(basename "${FILES[$i]}")"
            cat "${FILES[$i]}"
            printf "\n\n"
        done
    } > "$OUTPUT"

    exit 0

else
    # ---------- 人类模式 ----------
    REUSED=0   # 标记是否复用历史配置

    # 检测已有配置
    declare -a OLD_ORDERS OLD_NAMES
    if [ -f "$SETTING_OUTPUT" ]; then
        OLD_ORDERS=()
        OLD_NAMES=()
        while read -r line; do
            order=$(echo "$line" | sed 's/.*@order:[ ]*//')
            OLD_ORDERS+=("$order")
        done < <(grep '^% @order:' "$SETTING_OUTPUT")
        while read -r line; do
            name=$(echo "$line" | sed 's/.*@name:[ ]*//')
            OLD_NAMES+=("$name")
        done < <(grep '^% @name:' "$SETTING_OUTPUT")
        while [ ${#OLD_NAMES[@]} -lt ${#OLD_ORDERS[@]} ]; do
            OLD_NAMES+=("")
        done
        if [ ${#OLD_NAMES[@]} -gt ${#OLD_ORDERS[@]} ]; then
            OLD_NAMES=("${OLD_NAMES[@]:0:${#OLD_ORDERS[@]}}")
        fi

        if [ "${#OLD_ORDERS[@]}" -gt 0 ]; then
            printf "\n${GREEN}>>> 检测到已有配置 >>>${RESET}\n"
            for idx in "${!OLD_ORDERS[@]}"; do
                order="${OLD_ORDERS[$idx]}"
                name="${OLD_NAMES[$idx]}"
                found_idx=$(find_module_by_order_and_name "$order" "$name")
                if [ "$found_idx" -ne -1 ]; then
                    printf "${GREEN}✓${RESET} ${YELLOW}%-*s${RESET}${CYAN}(%s)${RESET}" \
                        "$col_width" "$(basename "${FILES[$found_idx]}")" "$order"
                    if [ -n "$name" ] && [ "$name" != "$(basename "${FILES[$found_idx]}")" ]; then
                        printf " ${RED}(原文件名: %s)${RESET}" "$name"
                    fi
                    printf "\n"
                else
                    printf "${RED}! 消失模块 order=%s name=%s${RESET}\n" "$order" "$name"
                fi
            done

            printf "是否使用上一次配置?[Y/n] "
            read -r reuse
            if [[ ! "$reuse" =~ ^[Nn]$ ]]; then
                declare -a SELECTED
                for idx in "${!OLD_ORDERS[@]}"; do
                    order="${OLD_ORDERS[$idx]}"
                    name="${OLD_NAMES[$idx]}"
                    found_idx=$(find_module_by_order_and_name "$order" "$name")
                    if [ "$found_idx" -ne -1 ]; then
                        SELECTED+=("$found_idx")
                    fi
                done
                REUSED=1   # 标记已复用
            fi
        fi
    fi

    # 如果没有 SELECTED（即未复用或没有旧配置），进入交互选择
    if [ -z "${SELECTED+x}" ] || [ "${#SELECTED[@]}" -eq 0 ]; then
        declare -a SELECTED
        global_num=1

        # 1. 必要模块 (0-19)
        printf "\n${CYAN}=== 必要模块 (0-19) ===${RESET}\n"
        declare -a REQ_INDICES
        for i in "${SORTED[@]}"; do
            if [ "${ORDERS[$i]}" -lt 20 ]; then
                REQ_INDICES+=("$i")
            fi
        done

        declare -a order_list
        for i in "${REQ_INDICES[@]}"; do
            order_list+=("${ORDERS[$i]}")
        done
        declare -a unique_orders=($(printf '%s\n' "${order_list[@]}" | sort -n -u))

        for ord in "${unique_orders[@]}"; do
            declare -a group=()
            for i in "${REQ_INDICES[@]}"; do
                if [ "${ORDERS[$i]}" -eq "$ord" ]; then
                    group+=("$i")
                fi
            done
            if [ ${#group[@]} -eq 1 ]; then
                SELECTED+=("${group[0]}")
                print_module "$global_num" "${group[0]}" 1
                global_num=$((global_num+1))
            else
                printf "\n${RED}冲突: order=%s 有多个模块，请选择一个保留${RESET}\n" "$ord"
                idx=0
                for g in "${group[@]}"; do
                    idx=$((idx+1))
                    name=$(basename "${FILES[$g]}")
                    printf "${RED}[冲突%d]${RESET} ${BOLD}${YELLOW}%s${RESET}${RESET} ${CYAN}(%d)${RESET}" \
                        "$idx" "$name" "${ORDERS[$g]}"
                    if [ -n "${DESCRIPTIONS[$g]}" ]; then
                        printf " ${GREEN}%s${RESET}" "${DESCRIPTIONS[$g]}"
                    fi
                    printf "\n"
                done
                while true; do
                    printf "请选择要保留的模块编号 (1-%d): " "${#group[@]}"
                    read -r choice
                    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#group[@]}" ]; then
                        SELECTED+=("${group[$((choice-1))]}")
                        print_module "$global_num" "${group[$((choice-1))]}" 1
                        global_num=$((global_num+1))
                        break
                    else
                        printf "${RED}无效输入，请重新输入${RESET}\n"
                    fi
                done
            fi
        done

        # 2. 推荐模块 (20-99)
        declare -a REC
        for i in "${SORTED[@]}"; do
            if [ "${ORDERS[$i]}" -ge 20 ] && [ "${ORDERS[$i]}" -lt 100 ]; then
                REC+=("$i")
            fi
        done
        if [ "${#REC[@]}" -gt 0 ]; then
            printf "\n${CYAN}=== 推荐模块 (20-99) ===${RESET}\n"
            declare -a REC_GLOBAL_IDS
            rec_idx=0
            for i in "${REC[@]}"; do
                print_module "$global_num" "$i" 1
                REC_GLOBAL_IDS[$rec_idx]="$global_num"
                rec_idx=$((rec_idx+1))
                global_num=$((global_num+1))
            done

            printf "是否启用全部推荐模块?[Y/n] "
            read -r ans
            if [[ "$ans" =~ ^[Nn]$ ]]; then
                printf "输入要取消的推荐模块的全局编号（空格分隔）："
                read -r remove
                declare -a NEW_REC
                for idx in "${!REC[@]}"; do
                    skip=0
                    for r in $remove; do
                        if [ "${REC_GLOBAL_IDS[$idx]}" -eq "$r" ]; then
                            skip=1
                            break
                        fi
                    done
                    [ "$skip" -eq 0 ] && NEW_REC+=("${REC[$idx]}")
                done
                REC=("${NEW_REC[@]}")
            fi
            SELECTED+=("${REC[@]}")
        fi

        # 3. 自选模块 (100+)
        declare -a OPT
        for i in "${SORTED[@]}"; do
            if [ "${ORDERS[$i]}" -ge 100 ]; then
                OPT+=("$i")
            fi
        done
        if [ "${#OPT[@]}" -gt 0 ]; then
            printf "\n${CYAN}=== 自选模块 (100-999) ===${RESET}\n"
            declare -a OPT_GLOBAL_IDS
            opt_idx=0
            for i in "${OPT[@]}"; do
                print_module "$global_num" "$i" 1
                OPT_GLOBAL_IDS[$opt_idx]="$global_num"
                opt_idx=$((opt_idx+1))
                global_num=$((global_num+1))
            done

            printf "输入需要加入的自选模块的全局编号（空格分隔）："
            read -r add
            declare -a ADDED_OPT
            for r in $add; do
                for idx in "${!OPT[@]}"; do
                    if [ "${OPT_GLOBAL_IDS[$idx]}" -eq "$r" ]; then
                        ADDED_OPT+=("${OPT[$idx]}")
                        break
                    fi
                done
            done
            SELECTED+=("${ADDED_OPT[@]}")
        fi
    fi

    # 最终排序（按 order）
    declare -a FINAL
    while read -r idx; do
        FINAL+=("$idx")
    done < <(
        for i in "${SELECTED[@]}"; do
            echo "${ORDERS[$i]} $i"
        done | sort -n | awk '{print $2}'
    )

    # ---------- 如果复用历史，直接生成；否则询问确认 ----------
    if [ $REUSED -eq 1 ]; then
        # 直接生成，不询问
        :
    else
        # 显示最终确认列表
        printf "\n${CYAN}=== 确认要加入的模块 ===${RESET}\n"
        global_num=1
        printf "${GREEN}>>> 必要模块 >>>${RESET}\n"
        for i in "${FINAL[@]}"; do
            if [ "${ORDERS[$i]}" -lt 20 ]; then
                print_module "$global_num" "$i" 0
                global_num=$((global_num+1))
            fi
        done
        printf "\n${GREEN}>>> 推荐模块 >>>${RESET}\n"
        for i in "${FINAL[@]}"; do
            if [ "${ORDERS[$i]}" -ge 20 ] && [ "${ORDERS[$i]}" -lt 100 ]; then
                print_module "$global_num" "$i" 0
                global_num=$((global_num+1))
            fi
        done
        printf "\n${GREEN}>>> 自选模块 >>>${RESET}\n"
        for i in "${FINAL[@]}"; do
            if [ "${ORDERS[$i]}" -ge 100 ]; then
                print_module "$global_num" "$i" 0
                global_num=$((global_num+1))
            fi
        done

        printf "\n确认生成?[Y/n] "
        read -r confirm
        [[ "$confirm" =~ ^[Nn]$ ]] && exit 0
    fi

    # 生成文件
    {
        printf "%% @description: 自动生成的LaTeX设置文件\n\n"
        for i in "${FINAL[@]}"; do
            printf "%% @name: %s\n" "$(basename "${FILES[$i]}")"
            cat "${FILES[$i]}"
            printf "\n\n"
        done
    } > "$OUTPUT"

    printf "\n${GREEN}✓ 已生成${RESET} ${YELLOW}%s${RESET}\n" "$OUTPUT"
fi