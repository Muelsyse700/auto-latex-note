#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# @description: 自动生成数学建模论文附录

"""
AutoAppendix.py - 从工作目录自动生成论文附录的 CSV 清单和 LaTeX 代码
用法: python AutoAppendix.py [工作目录]
      python AutoAppendix.py --init [工作目录]
      python AutoAppendix.py -h|--help
"""

import os
import sys
import csv

# ---------- 颜色定义 ----------
RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
PURPLE = "\033[35m"

# ---------- 常量 ----------
SKIP_MARK = "-skip"  # 文件名包含该标记则跳过

# ---------- 帮助信息 ----------
def print_help():
    help_text = f"""
{CYAN}用法:{RESET}
  python3 AutoAppendix.py [工作目录]
  python3 AutoAppendix.py --init [工作目录]
  python3 AutoAppendix.py -h | --help

{CYAN}功能:{RESET}
  在指定的工作目录下管理附录文件。
  使用 --init 可仅初始化目录结构后退出。
  交互菜单提供完整功能。

{CYAN}目录结构（自动创建）:{RESET}
  工作目录/
  └── appendix/
      ├── source-code/         # 存放 .py .m 代码
      ├── table/               # 存放 .xlsx 表格
      ├── other-materials/     # 存放其他材料
      ├── files.csv            # 文件清单（可手动编辑用途）
      └── appendix.tex         # 生成的 LaTeX 附录代码

{CYAN}交互菜单:{RESET}
  0. 初始化目录结构
  1. 读取文件列表并生成/更新 CSV
  2. 生成附录 .tex 文件
  q. 退出

{CYAN}示例:{RESET}
  python AutoAppendix.py                      # 使用当前目录，进入菜单
  python AutoAppendix.py /path/to/note        # 使用指定目录，进入菜单
  python AutoAppendix.py --init               # 初始化当前目录后退出
  python AutoAppendix.py --init /path/to/note # 初始化指定目录后退出
  python AutoAppendix.py -h                   # 显示本帮助
"""
    print(help_text)

# ---------- 参数解析 ----------
def parse_args():
    args = sys.argv[1:]
    if not args:
        return None, False, False  # target_dir, init_flag, help_flag
    if args[0] in ("-h", "--help"):
        return None, False, True
    if args[0] == "--init":
        # 后续可能有工作目录
        if len(args) >= 2 and not args[1].startswith("-"):
            return args[1], True, False
        else:
            return None, True, False
    # 普通工作目录
    if len(args) > 1:
        print(f"{RED}警告:{RESET} 多余参数将被忽略，只使用第一个参数作为目标目录。")
    return args[0], False, False

# ---------- 初始化环境 ----------
def init_environment(base_dir):
    """
    确保 appendix/ 目录及子目录存在，创建空 files.csv 和 appendix.tex 若不存在。
    """
    appendix_dir = os.path.join(base_dir, "appendix")
    os.makedirs(appendix_dir, exist_ok=True)

    subdirs = ["source-code", "table", "other-materials"]
    for sub in subdirs:
        os.makedirs(os.path.join(appendix_dir, sub), exist_ok=True)

    csv_path = os.path.join(appendix_dir, "files.csv")
    if not os.path.exists(csv_path):
        with open(csv_path, "w", encoding="utf-8-sig", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["序号", "文件名", "用途"])
        print(f"{GREEN}✓ 创建了 {csv_path}{RESET}")

    tex_path = os.path.join(appendix_dir, "appendix.tex")
    if not os.path.exists(tex_path):
        with open(tex_path, "w", encoding="utf-8") as f:
            f.write("")
        print(f"{GREEN}✓ 创建了 {tex_path}{RESET}")

    print(f"{GREEN}✅ 附录目录初始化完成：{appendix_dir}{RESET}")
    return appendix_dir

# ---------- 检查是否已初始化 ----------
def is_initialized(base_dir):
    appendix_dir = os.path.join(base_dir, "appendix")
    if not os.path.isdir(appendix_dir):
        return False
    subdirs = ["source-code", "table", "other-materials"]
    for sub in subdirs:
        if not os.path.isdir(os.path.join(appendix_dir, sub)):
            return False
    return True

# ---------- 功能1：读取文件列表更新 CSV ----------
def read_file_list(appendix_dir):
    code_dir = os.path.join(appendix_dir, "source-code")
    table_dir = os.path.join(appendix_dir, "table")
    materials_dir = os.path.join(appendix_dir, "other-materials")
    output_csv = os.path.join(appendix_dir, "files.csv")

    if not os.path.exists(output_csv):
        print(f"{RED}错误:{RESET} files.csv 不存在，请先运行初始化。")
        return

    existing_files = {}  # {文件名: 序号}
    rows = []            # 保存最终的行
    skipped_files = []   # 保存被跳过的文件名

    with open(output_csv, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                seq = int(row["序号"])
            except ValueError:
                continue
            fname = row["文件名"]
            usage = row["用途"]
            existing_files[fname] = seq
            rows.append([seq, fname, usage])

    max_seq = max(existing_files.values(), default=0)

    # 扫描 source-code
    if os.path.exists(code_dir):
        for fname in sorted(os.listdir(code_dir)):
            if fname.endswith((".py", ".m")):
                if SKIP_MARK in fname:
                    skipped_files.append(fname)
                    continue
                if fname not in existing_files:
                    max_seq += 1
                    rows.append([max_seq, fname, ""])

    # 扫描 table
    if os.path.exists(table_dir):
        for fname in sorted(os.listdir(table_dir)):
            if fname.endswith(".xlsx"):
                if SKIP_MARK in fname:
                    skipped_files.append(fname)
                    continue
                if fname not in existing_files:
                    max_seq += 1
                    rows.append([max_seq, fname, ""])

    # 扫描 other-materials
    if os.path.exists(materials_dir):
        for fname in sorted(os.listdir(materials_dir)):
            if SKIP_MARK in fname:
                skipped_files.append(fname)
                continue
            if fname not in existing_files:
                max_seq += 1
                rows.append([max_seq, fname, ""])

    rows_sorted = sorted(rows, key=lambda x: x[0])

    with open(output_csv, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(["序号", "文件名", "用途"])
        writer.writerows(rows_sorted)

    print(f"{GREEN}✅ 文件列表已更新: {output_csv}{RESET}")
    if skipped_files:
        print(f"{YELLOW}⭕ 被跳过的文件：{RESET}")
        for sf in skipped_files:
            print(f"  - {sf}")

# ---------- 功能2：生成 appendix.tex ----------
def generate_tex(appendix_dir):
    output_csv = os.path.join(appendix_dir, "files.csv")
    output_tex = os.path.join(appendix_dir, "appendix.tex")

    if not os.path.exists(output_csv):
        print(f"{RED}❌ 未找到 files.csv，请先运行初始化。{RESET}")
        return

    rows = []
    with open(output_csv, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                seq = int(row["序号"])
            except ValueError:
                continue
            rows.append((seq, row["文件名"], row["用途"].strip()))
    if not rows:
        print(f"{RED}❌ files.csv 为空，请添加文件后再试。{RESET}")
        return

    rows.sort(key=lambda x: x[0])

    tex_lines = []

    # 章节标题
    tex_lines.append(r"\section*{\texorpdfstring{附\hspace{2em}录}{附录}}\label{sec:appendix}")

    # -------- 附录表格头部 --------
    tex_lines.append(r"\begin{tcolorbox}[")
    tex_lines.append(r"    breakable,")
    tex_lines.append(r"    enforce breakable,")
    tex_lines.append(r"    colback=bgcolor,")
    tex_lines.append(r"    colframe=black,")
    tex_lines.append(r"    fonttitle=\bfseries,")
    tex_lines.append(r"    title={附录0 \quad 支撑材料的文件清单},")
    tex_lines.append(r"    sharp corners,")
    tex_lines.append(r"    coltitle=white,")
    tex_lines.append(r"    boxrule=0.75pt,")
    tex_lines.append(r"    left=2pt, right=2pt, top=2pt, bottom=2pt")
    tex_lines.append(r"]")
    tex_lines.append(r"    \centering")
    tex_lines.append(r"    \begin{tabularx}{\linewidth}{@{} Y Y @{}}")
    tex_lines.append(r"        \textbf{文件名} & \textbf{用途} \\")

    code_seq = 0
    code_mapping = {}  # {文件名: 代码专属序号}

    for csv_seq, fname, usage in rows:
        if fname.endswith(".py") or fname.endswith(".m"):
            code_seq += 1
            code_mapping[fname] = code_seq
            tex_lines.append(
                f"        \\Aref{{lst:{code_seq}}}{{{fname}}} & \\textit{{{usage}}} \\\\"
            )
        else:
            tex_lines.append(
                f"        \\ttfamily{{{fname}}} & \\textit{{{usage}}} \\\\"
            )

    tex_lines.append(r"    \end{tabularx}")
    tex_lines.append(r"\end{tcolorbox}")
    tex_lines.append("")  # 空行

    # ---- includecode 部分 ----
    for csv_seq, fname, usage in rows:
        if fname.endswith(".py"):
            lang = "mypython"
        elif fname.endswith(".m"):
            lang = "mymatlab"
        else:
            continue

        desc = usage if usage else "（无描述）"
        cseq = code_mapping.get(fname)
        if cseq is None:
            continue
        tex_lines.append(
            f"\\includecode[{lang}]{{附录{cseq} \\quad {desc}({fname})}}{{lst:{cseq}}}{{appendix/source-code/{fname}}}"
        )

    with open(output_tex, "w", encoding="utf-8") as f:
        f.write("\n".join(tex_lines))

    print(f"{GREEN}✅ 已生成 LaTeX 文件: {output_tex}{RESET}")

# ---------- 主菜单 ----------
def main():
    target_dir, init_flag, help_flag = parse_args()
    if help_flag:
        print_help()
        sys.exit(0)

    # 确定工作目录
    if target_dir is None:
        base_dir = os.getcwd()
    else:
        base_dir = os.path.abspath(target_dir)
        if not os.path.isdir(base_dir):
            print(f"{RED}错误:{RESET} 目录 '{base_dir}' 不存在。")
            sys.exit(1)

    # 如果带 --init，只初始化并退出
    if init_flag:
        init_environment(base_dir)
        sys.exit(0)

    # 进入交互菜单
    print(f"{CYAN}工作目录: {base_dir}{RESET}")
    while True:
        print(f"{PURPLE}🎚️ 请选择功能：{RESET}")
        print("0. 初始化目录结构")
        print("1. 读取文件列表并生成/更新 CSV")
        print("2. 生成附录 .tex 文件")
        print("q. 退出")

        choice = input("请输入选项 (0/1/2/q): ").strip().lower()

        if choice == "0":
            init_environment(base_dir)
            print()
        elif choice == "1":
            if not is_initialized(base_dir):
                print(f"{YELLOW}⚠️ 附录目录尚未初始化，请先执行选项 0。{RESET}\n")
                continue
            appendix_dir = os.path.join(base_dir, "appendix")
            read_file_list(appendix_dir)
            print()
        elif choice == "2":
            if not is_initialized(base_dir):
                print(f"{YELLOW}⚠️ 附录目录尚未初始化，请先执行选项 0。{RESET}\n")
                continue
            appendix_dir = os.path.join(base_dir, "appendix")
            generate_tex(appendix_dir)
            print()
        elif choice == "q":
            print(f"{GREEN}已退出{RESET}")
            break
        else:
            print(f"{RED}❌ 无效输入，请输入 0、1、2 或 q{RESET}\n")

if __name__ == "__main__":
    main()