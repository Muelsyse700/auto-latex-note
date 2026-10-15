
# auto-latex-note

一套用于高效管理 LaTeX 笔记项目的自动化工具链：一键初始化项目、模块化组装导言区、CSV 转表格、作业 PDF 自动编译、论文附录生成、编译文件清理与打印自动化。

所有功能通过统一入口 `note.sh` 的交互菜单调用，并共享一致的终端 UI 风格。

---

## 目录结构

```

auto-latex-note/
├── script/                          # 所有工具脚本
│   ├── note.sh                      # 主菜单（唯一推荐入口）
│   ├── init-update.sh               # 初始化/更新项目（菜单 1、2）      [隐藏]
│   ├── make-main-note.sh            # 交互式生成 main-note.tex          [隐藏]
│   ├── make-core.sh                 # 合并模板模块生成 core-setting.tex  [隐藏]
│   ├── make-homework.sh             # 生成并编译作业 PDF（菜单 6）
│   ├── auto-print.sh                # VirtualHere + HP 打印自动化（菜单 3）
│   ├── auto-table.py                # CSV → LaTeX 表格（菜单 4）
│   ├── auto-appendix.py             # 论文附录清单/代码附录生成          [隐藏]
│   ├── clean.sh                     # 清理编译辅助文件（菜单 5）
│   └── url.sh                       # URL 转义并复制到剪贴板（菜单 7）
├── template/                        # 模板与模块目录
│   ├── main-note.tex                # 主文件模板（非模块，无 @order）
│   ├── used-package.tex             # @order: 0    宏包依赖
│   ├── font-and-layout-setting*.tex # @order: 1    全局字体与页面布局
│   ├── cover-or-title-setting*.tex  # @order: 2    封面/标题样式
│   ├── box-setting.tex              # @order: 4    彩色文本框
│   ├── list-setting.tex             # @order: 5    列表样式
│   ├── caption-and-reference-setting.tex  # @order: 6   标题与交叉引用
│   ├── header-footer-setting*.tex   # @order: 7    页眉页脚
│   ├── compatibility-fixes.tex      # @order: 8    兼容性修复
│   ├── my-command.tex               # @order: 20   自定义命令
│   ├── code-box-setting.tex         # @order: 21   代码块样式
│   ├── appendix-style-CUMCM.tex     # @order: 100  数模论文附录样式
│   ├── cover.pdf                    # 默认封面
│   ├── settings.json                # VS Code 工作区设置（含编译配方）
│   ├── note.gitignore               # 笔记项目的 Git 忽略规则
│   └── logo/                        # 校徽等图片素材（logo.pdf 等）
└── README.md                        # 本文件
```

> 方括号 `[隐藏]` 表示该脚本不会出现在主菜单的脚本列表中，只通过隐藏菜单或其它脚本调用。

---

## 依赖

| 依赖 | 用途 | 必需性 |
| --- | --- | --- |
| **Bash** | 除 `auto-print.sh` 外的所有 `.sh` 脚本 | 必需 |
| **Zsh** | `auto-print.sh`（使用 zsh 通配限定符与 `[[ == <-> ]]` 语法） | 使用打印功能时必需 |
| **Python 3.6+** | `auto-table.py`、`auto-appendix.py`（使用 f-string） | 使用表格/附录功能时必需 |
| **Git** | `init-update.sh` 初始化仓库并首次提交 | 初始化时必需 |
| **XeLaTeX** | `make-homework.sh` 编译作业；笔记本体编译 | 必需 |
| **macOS 命令 `pbcopy`** | `url.sh` 复制到剪贴板 | 仅 `url.sh` |
| **macOS 命令 `ioreg` / `open` / `osascript`** | `auto-print.sh` 设备检测、打开打印应用、退出 VirtualHere | 仅 `auto-print.sh` |
| **VirtualHere 客户端 + HP 应用** | `auto-print.sh` 转发 USB 打印机 | 仅 `auto-print.sh` |

Linux / WSL 用户：`pbcopy` 可替换为 `xclip` / `wl-copy`；`auto-print.sh` 为 macOS 专用，如需移植须重写设备检测（`ioreg`）与关闭逻辑（`osascript`）。

---

## 快速开始

### 1. 赋予脚本执行权限

```bash
cd /path/to/auto-latex-note
chmod +x script/*.sh script/*.py
```

### 2. 将 `note.sh` 安装到 PATH（推荐）

**只推荐将 `note.sh` 加入系统 PATH**，其它脚本无需暴露，全部通过 `note.sh` 主菜单调用。

```bash
# 方式一：软链接（推荐）
mkdir -p ~/bin
export PATH="$HOME/bin:$PATH"     # 可写入 ~/.zshrc 或 ~/.bashrc 以持久化
ln -s /path/to/auto-latex-note/script/note.sh ~/bin/note

# 方式二：直接把 script/ 目录加入 PATH（简单，但会暴露所有脚本）
export PATH="/path/to/auto-latex-note/script:$PATH"
```

完成后在任意位置运行 `note`（或 `note.sh`，取决于链接名）。

### 3. 初始化第一个笔记项目

```bash
mkdir my-note && cd my-note
note
```

在主菜单选择 **1) 初始化工具链**，随后按提示输入笔记标题、英文标题、作者、日期、GitHub、ORCID。脚本会自动：

1. 创建 `table/`（含 `Input/`、`Output/`、`table-index.txt`）、`figure/`、`chapter/`（含 `chapter1.tex`）、`setting/`、`reference/`、`.vscode/`；
2. 由模板生成 `main-note.tex`；
3. 交互式组装并生成 `setting/core-setting.tex`；
4. 复制 `setting/cover.pdf`、`.vscode/settings.json`、`.gitignore`；
5. `git init -b main` 并提交首次 commit。

完成后用 VS Code 打开，选择 `XeLaTeX*2` 配方编译两次即可。

---

## 主菜单 `note.sh`

`note.sh` 会扫描同目录下的所有 `.sh` / `.py` 脚本，读取其 `@description` 注释生成菜单。

```
latexNote 工具
当前目录：/path/to/my-note

=== 工具链 ===
  1) 初始化工具链
     初始化当前目录的 latexNote 项目
  2) 更新模板工具链
     更新当前目录的 latexNote 模板

=== 脚本工具 ===
  3) auto-print.sh
     自动启动 VirtualHere，检测 HP 136a 连接后启动 HP 打印
  4) auto-table.py
     将csv文件转换为latex表格
  5) clean.sh
     清理 LaTeX 编译产生的辅助文件
  6) make-homework.sh
     生成作业PDF的辅助脚本
  7) url.sh
     将 URL 转义为 LaTeX 安全格式并复制到剪贴板

  *) 显示隐藏脚本    q) 退出

请选择：
```

### 交互规则

| 输入 | 行为 |
| --- | --- |
| `数字` | 运行对应编号的工具（自动把当前工作目录作为第一个参数传入） |
| `数字 -h` / `数字 --help` | 显示该脚本的帮助信息而非执行 |
| `*` | 进入隐藏脚本菜单（`b` 返回主菜单、`q` 退出） |
| `q` / `Q` | 退出 |
| `Enter` | 刷新菜单 |

> **编号会随脚本数量变化**：编号 1、2 固定为工具链功能；3 号及以后按脚本文件名的字母顺序动态生成。新增脚本后原有编号可能整体后移，请以菜单显示为准。

---

## 工具链工作原理

### 模板模块协议

`template/` 下的 `.tex` 文件（除 `main-note.tex` 外）都是**模块**，头部由约定注释声明元信息：

```latex
% @order: 6
% @description: 设置图表标题格式、交叉引用格式
% @\usepackage{...}   % 可选，会被收集到 used-package.tex
```

- **第 1 行 `% @order: N`** —— 必填，决定模块在 `core-setting.tex` 中的顺序与分区；
- **第 2 行 `% @description: ...`** —— 可选，模块用途描述，显示在交互菜单中；
- **文件头部连续的 `% @\usepackage...` 行** —— 可选，`make-core.sh` 会收集这些行并注入到 `order=0` 模块的 `% @others` 标记处，使宏包集中在导言区最前部加载；
- 缺少 `% @order:` 的文件（如 `main-note.tex`）不会被当作模块处理。

### `@order` 分区规则

| 区间 | 类别 | 规则 |
| --- | --- | --- |
| `0` | 宏包依赖 | 必须存在且唯一（`used-package.tex`），`% @others` 标记是宏包注入点 |
| `1 – 19` | **必要模块** | 按 order 分组；同一 order 只能保留一个文件，出现多个时需交互选择（冲突解决） |
| `20 – 99` | **推荐模块** | 默认全部启用，可输入编号取消个别模块 |
| `100 +` | **自选模块** | 默认不启用，需手动输入编号加入 |

同名不同用途的模块通过 order 分组实现「多选一」，例如：

- `order: 1` → `font-and-layout-setting.tex` / `-CUMCM.tex` / `-homework.tex`
- `order: 2` → `cover-or-title-setting.tex` / `-CUMCM.tex` / `-homework.tex`
- `order: 7` → `header-footer-setting.tex` / `-homework.tex`

### 生成结果与「复用上次配置」

`make-core.sh` 把选中的模块按 order 拼接为 `core-setting.tex`，每个模块前写入 `% @name:` 标记，模块自身的 `% @order:` 行保留在内容中。生成的文件形如：

```latex
% @description: 自动生成的LaTeX设置文件

% @name: used-package.tex
% @order: 0
...
% @others
% @name: font-and-layout-setting.tex
% @order: 1
...
```

再次运行 `make-core.sh` 时，脚本会读取现有 `core-setting.tex` 的 `% @order:` / `% @name:` 记录，逐条与本机模块比对并提示 `是否使用上一次配置?[Y/n]`，实现配置的快速复现；若模块被重命名或删除，会以 `! 消失模块 order=... name=...` 标出。

---

## 各工具详解

### `note.sh` —— 主菜单

统一入口。除生成菜单外，还负责把当前工作目录传递给被调用的脚本（`-h` / `--help` 除外），因此**所有工具都作用于启动 `note.sh` 时所在的目录**。脚本必须通过 `chmod +x` 赋予可执行权限才会被列出。

### `init-update.sh` —— 初始化 / 更新（隐藏，菜单 1、2）

```bash
init-update.sh [-u|--update] [目标目录]
```

| 模式 | 行为 |
| --- | --- |
| 初始化（默认） | 创建目录结构与 `main-note.tex`，生成 `setting/core-setting.tex`，复制 `setting/cover.pdf`、`.vscode/settings.json`、`.gitignore`，`git init` 并首次提交 |
| 更新（`-u`） | 覆盖 `setting/cover.pdf`、`.vscode/settings.json`、`.gitignore`，并重新生成 `setting/core-setting.tex`；**不修改 `main-note.tex`** |

初始化流程会依次调用 `make-main-note.sh` 与 `make-core.sh`，因此这两个脚本也可单独使用（见下）。

### `make-main-note.sh` —— 生成 `main-note.tex`（隐藏）

```bash
make-main-note.sh [目标目录]
```

从 `template/main-note.tex` 读取 `\covertitle`、`\coverengtitle`、`\coverauthor`、`\coverdate`、`\covergithub`、`\coverorcid` 的当前值作为默认值，逐项询问后写回。日期留空时自动填入当天日期。

### `make-core.sh` —— 生成 `core-setting.tex`（隐藏）

```bash
make-core.sh [目标目录]              # 人类交互模式
make-core.sh --auto <目标目录>       # 机器自动化模式
```

- **人类模式**：列出必要/推荐/自选模块，处理 order 冲突，末尾打印「确认要加入的模块」清单并等待确认；
- **机器模式（`--auto`）**：不打印菜单。遇到 order 冲突时向 stdout 输出一行 `@CONFLICT order=N`，然后从 stdin 读取一行文件名作为选择；出错时输出 `ERROR: ...` 并返回非零。该协议供 `make-homework.sh` 通过 FIFO 驱动，实现作业模板的无人值守组装。

输出文件写入 `<目标目录>/core-setting.tex`（`init-update.sh` 随后将其移动到 `setting/`）。

### `make-homework.sh` —— 生成并编译作业 PDF

```bash
make-homework.sh <工作目录>
```

工作目录下应存在 `homework/`，其中每个子目录（如 `week1/`）是一份作业，内含 `homework.tex`。脚本流程：

1. 若 `homework/` 不存在，询问是否创建 `homework/week1/homework.tex` 后退出；
2. 列出 `homework/` 下所有作业目录供选择；
3. **自动收集元信息**：
   - 课程名 ← 工作目录 `main-note.tex` 中的 `\covertitle`；
   - 周次 ← `homework.tex` **前 5 行**内的 `% @week N` 注释，其次从目录名 `weekN` 解析，最后才询问；
   - 附加说明 ← 同区域的 `% @ps ...` 注释，会以脚注形式插入正文前；
   - 姓名、学号：交互输入；
4. 调用 `make-core.sh --auto` 生成 `core-setting.tex`，冲突按内置映射自动选择：
   `order 1 → font-and-layout-setting-homework.tex`、`order 2 → cover-or-title-setting-homework.tex`、`order 7 → header-footer-setting-homework.tex`；
5. 生成 `make.tex`（`ctexart` 文档类）并从 `template/logo/` 复制 `logo.pdf`；
6. 用 XeLaTeX 连续编译两次，随后进入操作菜单：

| 选项 | 行为 |
| --- | --- |
| `1` | 用系统默认 PDF 阅读器打开 `make.pdf`（自动适配 `xdg-open` / `open` / `wslview` / `cygstart`） |
| `2` | 再编译一次 |
| `3` | 收尾（重命名 PDF 为 `homework-weekN.pdf`、清理中间文件）并调用 `auto-print.sh` 打印 |
| `q` | 收尾并退出 |

收尾会删除 `make.tex`、`make.aux`、`make.log`、`make.out`、`core-setting.tex`、`logo.pdf`，只保留编译产物 PDF。

### `auto-print.sh` —— 打印自动化（macOS）

```bash
auto-print.sh [工作目录] [文件名]
```

1. 校验 VirtualHere 客户端路径（默认 `~/Applications/VirtualHereUniversal.app/Contents/MacOS/VirtualHereUniversal`）；
2. 未指定文件名时，列出工作目录下所有可打印文件（PDF / Office / 图片 / 文本）供选择；
3. 启动 VirtualHere，轮询 `ioreg` 检测 HP 136a（USB VID `0x03f0` / PID `0xf22a`）是否挂载，超时 60 秒；
4. 检测到后等待设备稳定并二次确认，再用 `open -a HP <文件>` 发起打印；
5. 等待 HP 进程退出后自动关闭 VirtualHere（本次启动的进程优先，否则用 AppleScript 退出应用）。

如需适配其它打印机/客户端，修改脚本顶部配置区的 `VIRTUALHERE_BIN`、`HP_APP`、`HP_USB_VENDOR`、`HP_USB_PRODUCT` 及三个等待时长即可。

### `auto-table.py` —— CSV 转 LaTeX 表格

```bash
python3 auto-table.py [目标目录]
```

将 `table/Input/` 中**唯一**的 CSV 转换为可跨页的 `xltabular` 表格。流程与约定：

1. 放入 UTF-8 编码的 CSV（一次一个，多余或缺少都会报错退出）；
2. 运行脚本，生成：
   - `table/Output/<6 位哈希>/<6 位哈希>.tex` —— 表格代码；
   - `table/Output/<6 位哈希>/<原文件名>.csv` —— 原 CSV 被**移动**到此归档；
   - `table/table-index.txt` 追加 `\input{...}` 与 `\cref{...}` 两行（已存在则去重，不重复追加）；
3. 终端打印可直接复制的插入/引用代码。

细节：

- 哈希为 CSV 文件名（不含扩展名）的 MD5 前 6 位，**仅依赖文件名**，故同名 CSV 重复处理会覆盖同一输出与同一个 `\label`；
- 列宽按字符宽度比例分配（非 ASCII 字符按 2 计），格式为 `>{\hsize=<比例>\hsize}Z`；
- 表头在跨页时自动重复（`\endfirsthead` / `\endhead` / `\endfoot` / `\endlastfoot`）；
- 单元格中的 `\ & % $ # _ { } ~ ^` 会被自动转义；
- 生成代码使用 `\toprule` / `\midrule` / `\bottomrule`，需要 `booktabs`、`xltabular` 等宏包支持。

### `auto-appendix.py` —— 论文附录生成（隐藏）

```bash
python3 auto-appendix.py [工作目录]
python3 auto-appendix.py --init [工作目录]   # 仅初始化目录结构后退出
```

交互菜单：`0` 初始化目录结构、`1` 扫描文件并更新 CSV 清单、`2` 生成 `appendix.tex`、`q` 退出。

自动创建的目录结构：

```
appendix/
├── source-code/        # .py .m 代码
├── table/              # .xlsx 表格
├── other-materials/    # 其它材料
├── files.csv           # 文件清单（序号,文件名,用途，utf-8-sig 编码，可用 Excel 编辑）
└── appendix.tex        # 生成的 LaTeX 附录代码
```

- 文件名含 `-skip` 标记（可改 `SKIP_MARK`）的文件会被跳过；
- 清单按序号排序，新增文件自动追加序号，**手工填写的「用途」列在重新扫描时保留**；
- 生成的 `appendix.tex` 包含：`tcolorbox` + `tabularx` 的文件清单表，以及代码文件的 `\includecode` 附录（`.py` → `mypython`、`.m` → `mymatlab`）；
- 依赖模板命令 `\Aref` 与 `\includecode`：前者来自 `appendix-style-CUMCM.tex`（order 100），后者还可见于 `code-box-setting.tex`（order 21），使用前请确保对应模块已加入 `core-setting.tex`。

### `clean.sh` —— 清理编译辅助文件

```bash
clean.sh [目录]
```

递归删除指定目录（默认当前目录）及其子目录中的 LaTeX 辅助文件：

`.aux` `.log` `.toc` `.out` `.bbl` `.blg` `.synctex.gz` `.fdb_latexmk` `.fls` `.nav` `.snm` `.vrb` `.bcf` `.run.xml`

每删除一个文件都会以红色打印其路径，便于确认影响范围。

### `url.sh` —— URL 转义并复制到剪贴板

```bash
url.sh
```

提示输入 URL，转义为 LaTeX 安全格式后复制到系统剪贴板（macOS `pbcopy`）并回显：

| 原字符 | 转义结果 |
| --- | --- |
| `\` | `\textbackslash{}` |
| `# $ % & _ { }` | `\#` `\$` `\%` `\&` `\_` `\{` `\}` |
| `~` | `\textasciitilde{}` |
| `^` | `\textasciicircum{}` |

除 `-h` / `--help` 外，任何命令行参数都会被忽略（防呆设计）。

---

## 典型工作流

**日常笔记**

1. `note` → `1` 初始化项目（或 `2` 同步最新模板）；
2. 在 `chapter/` 写章节，在 `main-note.tex` 中 `\input` 引入；
3. VS Code 使用 `XeLaTeX*2` 编译；
4. 编译文件过多时 → `note` → `5` 清理。

**插入表格**：把 CSV 放进 `table/Input/` → `note` → `4` → 复制终端输出的 `\input` / `\cref` 到正文。需要更新数据时用**同名** CSV 覆盖后重跑。

**写作业**：在 `homework/weekN/homework.tex` 顶部写好 `% @week N`、`% @ps 说明` → `note` → `6` → 选择作业 → 输入姓名学号 → 编译完成后可直接选择 `3` 打印。

**数模论文附录**：`note` → `*` → `auto-appendix.py` → `0` 初始化 → 放入代码/表格/材料 → `1` 更新清单并补全「用途」列 → `2` 生成 `appendix.tex`，然后在正文 `\input{appendix/appendix.tex}`。

---

## 自定义模板

### 修改封面默认信息

编辑 `template/main-note.tex` 中 `\covertitle`、`\coverengtitle`、`\coverauthor`、`\coverdate`、`\covergithub`、`\coverorcid` 的值。这些值会成为运行初始化 / `make-main-note.sh` 时的预填默认值（日期留空则取当天）。

### 修改导言区设置

直接编辑 `template/` 下对应的模块文件，然后通过 `note` → `2` 更新模板工具链，重新生成 `setting/core-setting.tex`。若要新增一组样式，按 `@order` 协议新建 `.tex` 文件即可，无需改动任何脚本。

### 替换封面与校徽

用同名文件替换 `template/cover.pdf` 与 `template/logo/logo.pdf`，再执行更新模板操作。`cover.pdf` 会被复制到项目的 `setting/`；`logo.pdf` 在生成作业时复制到作业目录。

### 修改 VS Code 设置或忽略规则

编辑 `template/settings.json` 或 `template/note.gitignore`，更新模板后会自动覆盖到项目的 `.vscode/settings.json` 与 `.gitignore`。

---

## 为工具链添加新脚本

新脚本放入 `script/` 目录，并遵循以下规范即可自动出现在 `note.sh` 菜单中。

### 1. 文件命名与位置

- 支持 `.sh`（Bash）与 `.py`（Python）两种格式，放在 `script/` 下；
- 若使用 zsh 特有语法，shebang 写 `#!/bin/zsh`（如 `auto-print.sh`）。

### 2. 声明描述（决定是否出现在菜单）

```bash
# @description: 简短描述该脚本的功能      ← 出现在主菜单的「脚本工具」区
# @description*: 内部脚本，请勿直接调用    ← 收入隐藏菜单（按 * 进入）
```

Python 脚本同样使用 `# @description:` 形式。未声明描述时菜单显示「无描述」。

> 被其它脚本调用的内部工具（如 `make-core.sh`、`make-main-note.sh`）建议标记为 `@description*`，避免用户误用。

### 3. 支持 `-h` / `--help`

传入 `-h` 或 `--help` 时打印用法说明并以状态码 `0` 退出。

### 4. 参数约定

接受一个可选的目标目录作为**第一个参数**，缺省时使用当前工作目录。`note.sh` 会自动把启动目录作为该参数传入，保证脚本在正确的上下文中运行。

### 5. 返回值与可执行权限

成功返回 `0`，失败返回非零并给出可读的错误信息；同时 `chmod +x script/新脚本`，否则 `note.sh` 无法运行它。

### 6. 统一 UI 风格

所有脚本共用同一套 ANSI 颜色变量，**定义块完全一致**（`.sh` 与 `.py` 皆然）：

```bash
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'
```

| 颜色 | 用途 |
| --- | --- |
| `PURPLE` | 区块标题 `=== xxx ===` / `>>> xxx >>>`、页面标题、菜单编号 `[1]` `3)`、可复制的 LaTeX 代码 |
| `YELLOW` | **路径与文件名**、警告、`[默认值]` |
| `CYAN` | 输入提示、进度信息（`正在...`）、帮助页标签与字段名（`目标目录：`） |
| `GREEN` | 成功提示、`✓`、已完成 / 已选择状态 |
| `RED` | 错误（`错误：` / `❌` / `无效输入`）、冲突与被删除项的标签 |

写法约定：

- **路径与文件名一律 `YELLOW`**，这是唯一用于表示文件的颜色；
- 成功行写作 `${GREEN}✓${RESET} 描述 ${YELLOW}路径${RESET}` —— `✓` 绿色，描述用默认色，路径黄色；
- 错误行写作 `${RED}错误：${RESET}详情` —— 仅 `错误：` 标签为红色，详情保持默认色，其中的路径仍为黄色；
- 输入提示（含 `[Y/n]` 确认）统一 `CYAN`，`\n` 放在颜色转义之外；
- 不使用 `BOLD`、`BLUE`(34)；`\033[35m` 统一命名为 `PURPLE`（不再叫 `MAGENTA`）。

> 目前仅 `auto-appendix.py` 保留了 emoji 前缀（`✅` `❌` `⚠️` `⭕` `🎚️`），其余脚本使用 `✓`。新增脚本请沿用 `✓`。

### 示例模板（Bash）

```bash
#!/bin/bash

# @description: 示例脚本，演示如何符合规范

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
PURPLE='\033[35m'

usage() {
    printf '%b\n' "${CYAN}用法:${RESET} ${YELLOW}$(basename "$0")${RESET} [目标目录]"
    printf '示例脚本描述\n'
    exit 0
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

TARGET_DIR="${1:-.}"
printf '%b\n' "${PURPLE}=== 开始处理 ===${RESET}"
# 后续脚本逻辑...
printf '%b\n' "${GREEN}✓${RESET} 处理完成 ${YELLOW}%s${RESET}" "$TARGET_DIR"
```

---

## 常见问题

**Q：编译提示缺少宏包怎么办？**
A：`core-setting.tex` 由模块拼接而成，宏包声明集中在 `used-package.tex` 及其它模块头部的 `% @\usepackage` 行。新增依赖时改模板模块后重新生成，不要直接编辑 `setting/core-setting.tex`（下次更新会被覆盖）。

**Q：`auto-table.py` 报「必须只有一个 CSV 文件」？**
A：`table/Input/` 一次只允许一个 CSV。正常情况下处理后的 CSV 会被移动到 `table/Output/<哈希>/` 归档，若被中断残留则需手动清理。

**Q：表格 `\cref` 编号会变吗？**
A：`\label` 由 CSV **文件名**哈希决定，文件名不变则编号稳定；重命名 CSV 会产生新表格与新标签。

**Q：能否在 Windows 上使用？**
A：建议使用 WSL2 或 Git Bash。`url.sh` 的剪贴板命令需改为 `clip`，`auto-print.sh` 依赖 macOS 的 `ioreg` / `osascript` / VirtualHere，需重写后才能移植。

**Q：编译笔记用什么命令？**
A：`xelatex` 连续编译两次，或直接使用 `.vscode/settings.json` 中预置的 `XeLaTeX*2` 配方（`xelatex -> bibtex -> xelatex*2` 配方用于需要参考文献的场景）。

**Q：如何添加新章节？**
A：在 `chapter/` 下创建 `chapterX.tex`，并在 `main-note.tex` 中 `\include{chapter/chapterX}` 或 `\input{chapter/chapterX}`。

**Q：`table/table-index.txt` 有什么用？**
A：集中记录所有已生成表格的 `\input` 与 `\cref` 命令，行尾带表名注释，方便直接复制。

**Q：修改了模板，如何同步到已有项目？**
A：在项目目录运行 `note`，选择 `2) 更新模板工具链`（等价于 `init-update.sh -u .`）。该操作只更新模板类文件与 `core-setting.tex`，不会改动 `main-note.tex`。

**Q：菜单编号和我预想的不一致？**
A：编号 3 及以后按脚本文件名字母序动态生成，新增或删除脚本都会导致编号变化。

---

## 贡献与许可

本项目基于 MIT License 发布。

---

**Happy TeXing!** 🚀
