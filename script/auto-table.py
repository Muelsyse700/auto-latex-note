#!/usr/bin/env python3

# @description: 将csv文件转换为latex表格

"""
AutoTab.py - 从 CSV 自动生成 LaTeX 表格 (xltabular)
用法: python AutoTab.py [目标目录]
        python AutoTab.py -h|--help
"""

import os
import sys
import shutil
import csv
import hashlib

# ---------- 颜色定义 ----------
RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
PURPLE = "\033[35m"

# ---------- 帮助信息 ----------
def print_help():
    """打印帮助信息"""
    help_text = f"""
{CYAN}用法:{RESET}
  python3 auto-table.py [目标目录]
  python3 auto-table.py -h | --help

{CYAN}功能:{RESET}
  从 Input 文件夹中的唯一 CSV 文件自动生成 LaTeX 表格代码，
  并输出到 Output 子目录，同时更新 table-index.txt 索引文件。

{CYAN}表格转换功能使用步骤:{RESET}

  {GREEN}插入新表格:{RESET}
    1. 将 UTF-8 编码的逗号分隔 CSV 文件放入 Input 文件夹（一次一个）。
    2. 运行 auto-table.py(可指定项目根目录)。
    3. 在终端复制插入代码至正文中。
    4. 完成表格插入。

  {GREEN}更新表格数据:{RESET}
    1. 将更新后的 CSV 重新放入 Input 文件夹（不必删除原来的，不要改动 CSV 的文件名）。
    2. 运行 auto-table.py。
    3. 更新完成（同名表格会被覆盖）。

  {GREEN}查找插入和引用代码:{RESET}
    1. 打开 table-index.txt。
    2. 根据语句后注释的提示寻找你需要的语句。

{CYAN}目录结构要求:{RESET}
  目标目录（默认为当前工作目录）下必须包含 table/ 子目录，
  其中应有 Input/、Output/ 和 table-index.txt。
  脚本会在该 table/ 目录下完成所有操作。

{CYAN}示例:{RESET}
  python auto-table.py                      # 使用当前目录
  python auto-table.py /path/to/note        # 使用指定目录
  python auto-table.py -h                   # 显示本帮助
"""
    print(help_text)


# ---------- 参数解析 ----------
def parse_args():
    args = sys.argv[1:]
    if not args:
        return None, False  # 返回目标目录(None表示当前)和是否帮助
    if args[0] in ("-h", "--help"):
        return None, True
    # 取第一个参数作为目标目录
    if len(args) > 1:
        print(f"{RED}警告:{RESET} 多余参数将被忽略，只使用第一个参数作为目标目录。")
    target = args[0]
    return target, False


# ---------- 转义 LaTeX 特殊字符 ----------
def escape_latex(s):
    s = str(s)
    result = []
    for ch in s:
        if ch == '\\':
            result.append(r'\textbackslash{}')
        elif ch == '&':
            result.append(r'\&')
        elif ch == '%':
            result.append(r'\%')
        elif ch == '$':
            result.append(r'\$')
        elif ch == '#':
            result.append(r'\#')
        elif ch == '_':
            result.append(r'\_')
        elif ch == '{':
            result.append(r'\{')
        elif ch == '}':
            result.append(r'\}')
        elif ch == '~':
            result.append(r'\textasciitilde{}')
        elif ch == '^':
            result.append(r'\^{}')
        else:
            result.append(ch)
    return ''.join(result)


# ---------- 指派哈希 ----------
def stable_hash(name, length=6):
    h = hashlib.md5(name.encode("utf-8")).hexdigest()
    return h[:length]


# ---------- 计算字符宽度（用于列宽比例） ----------
def str_width(s):
    w = 0
    for ch in str(s):
        w += 2 if ord(ch) > 127 else 1
    return w


# ---------- 主函数 ----------
def main():
    target_dir, is_help = parse_args()
    if is_help:
        print_help()
        sys.exit(0)

    # 确定项目根目录（base_dir）
    if target_dir is None:
        base_dir = os.getcwd()
    else:
        base_dir = os.path.abspath(target_dir)
        if not os.path.isdir(base_dir):
            print(f"{RED}错误:{RESET} 目录 '{base_dir}' 不存在。")
            sys.exit(1)

    # 检查 table 子目录
    table_dir = os.path.join(base_dir, "table")
    if not os.path.isdir(table_dir):
        print(f"{RED}错误:{RESET} 在 '{base_dir}' 下未找到 table/ 子目录。")
        print(f"{YELLOW}提示:{RESET} 请确保目录结构正确（包含 table/Input/, table/Output/, table/table-index.txt）。")
        sys.exit(1)

    input_dir = os.path.join(table_dir, "Input")
    output_dir = os.path.join(table_dir, "Output")
    index_file = os.path.join(table_dir, "table-index.txt")

    # 确保 Input 和 Output 存在
    os.makedirs(input_dir, exist_ok=True)
    os.makedirs(output_dir, exist_ok=True)

    # ---------- 寻找唯一 CSV ----------
    csv_files = [f for f in os.listdir(input_dir) if f.endswith(".csv")]
    if len(csv_files) == 0:
        print(f"{RED}错误:{RESET} Input 文件夹中没有 CSV 文件。")
        sys.exit(1)
    if len(csv_files) > 1:
        print(f"{RED}错误:{RESET} Input 文件夹中必须只有一个 CSV 文件，当前有 {len(csv_files)} 个。")
        sys.exit(1)

    csv_file = csv_files[0]
    csv_path = os.path.join(input_dir, csv_file)
    table_name = os.path.splitext(csv_file)[0]
    hash_code = stable_hash(table_name)
    label_name = hash_code

    # ---------- 读取 CSV ----------
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = list(csv.reader(f))
    if not reader:
        print(f"{RED}错误:{RESET} CSV 文件为空。")
        sys.exit(1)
    header = reader[0]
    rows = reader[1:] if len(reader) > 1 else []

    # ---------- 计算列宽比例 ----------
    col_widths = []
    for col_i in range(len(header)):
        max_len = str_width(header[col_i])
        for row in rows:
            if col_i < len(row):
                max_len = max(max_len, str_width(row[col_i]))
        col_widths.append(max_len)
    total = sum(col_widths)
    if total == 0:
        col_ratios = [1.0 / len(header) for _ in header]
    else:
        col_ratios = [round(w / total, 2) for w in col_widths]

    col_formats = [f">{{\\hsize={r}\\hsize}}Z" for r in col_ratios]
    col_format = " ".join(col_formats)

    # ---------- 构造 LaTeX 代码 ----------
    latex_lines = []
    latex_lines.append(f"% Auto-generated from {csv_file}")
    latex_lines.append(f"\\begin{{xltabular}}{{\\textwidth}}{{@{{}} {col_format} @{{}}}}")
    latex_lines.append(f"\\caption{{{table_name}}} \\label{{tab:{label_name}}} \\\\")
    latex_lines.append("\\toprule[0.08em]")
    latex_lines.append(
        " & ".join([f"\\textbf{{{escape_latex(col)}}}" for col in header]) + " \\\\"
    )
    latex_lines.append("\\midrule[0.05em]")
    latex_lines.append("\\endfirsthead")
    latex_lines.append(
        f"\\multicolumn{{{len(header)}}}{{c}}{{表\\thetable \\quad {escape_latex(table_name)}(续)}} \\\\"
    )
    latex_lines.append("\\toprule[0.08em]")
    latex_lines.append(
        " & ".join([f"\\textbf{{{escape_latex(col)}}}" for col in header]) + " \\\\"
    )
    latex_lines.append("\\midrule[0.05em]")
    latex_lines.append("\\endhead")
    latex_lines.append("\\midrule[0.05em]")
    latex_lines.append(f"\\multicolumn{{{len(header)}}}{{r@{{}}}}{{(接下表)}} \\\\")
    latex_lines.append("\\endfoot")
    latex_lines.append("\\endlastfoot")

    for row in rows:
        # 确保行长度与表头一致，不足则补空
        filled = row + [""] * (len(header) - len(row))
        line = " & ".join([escape_latex(cell) for cell in filled]) + " \\\\"
        latex_lines.append(line)

    latex_lines.append("\\bottomrule[0.08em]")
    latex_lines.append("\\end{xltabular}")

    latex_content = "\n".join(latex_lines)

    # ---------- 生成输出子目录 ----------
    output_subdir = os.path.join(output_dir, label_name)
    os.makedirs(output_subdir, exist_ok=True)

    # ---------- 移动 CSV ----------
    shutil.move(csv_path, os.path.join(output_subdir, csv_file))

    # ---------- 写入 TEX ----------
    output_tex_path = os.path.join(output_subdir, f"{label_name}.tex")
    with open(output_tex_path, "w", encoding="utf-8") as f:
        f.write(latex_content)

    # ---------- 更新索引文件 ----------
    input_line = f"\\input{{table/Output/{label_name}/{label_name}.tex}} % 表：{table_name}"
    ref_line = f"\\cref{{tab:{label_name}}}"

    existing_lines = []
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            existing_lines = f.read().splitlines()

    # 检查是否已存在相同输入行（避免重复追加）
    if input_line not in existing_lines:
        with open(index_file, "a", encoding="utf-8") as f:
            f.write(input_line + "\n")
            f.write(ref_line + "\n\n")
        print(f"{GREEN}✓ 已生成 LaTeX 表格：{YELLOW}{output_tex_path}{RESET}")
        print(f"{GREEN}✓ 已更新索引文件：{YELLOW}{index_file}{RESET}")
    else:
        print(f"{GREEN}✓ 已覆盖同名表格，已更新对应的 LaTeX 表格：{YELLOW}{output_tex_path}{RESET}")
        print(f"{GREEN}✓ 索引文件无需更改：{YELLOW}{index_file}{RESET}")

    # ---------- 输出提示 ----------
    print(f"{CYAN}[label] tab:{label_name}{RESET}")
    print(f"{CYAN}在文档中拷贝以下命令以插入或引用该表格：{RESET}")
    print(f"{PURPLE}\\input{{table/Output/{label_name}/{label_name}.tex}} % 表：{table_name}{RESET}")
    print(f"{PURPLE}\\cref{{tab:{label_name}}}{RESET}\n")


if __name__ == "__main__":
    main()
