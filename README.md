
# auto-latex-note

一套用于高效管理 LaTeX 笔记项目的自动化工具链，实现快速初始化项目、生成表格、清理编译文件，告别重复劳动。

---

## 目录结构
```

auto-latex-note/
├── script/                    # 所有工具脚本
│   ├── note.sh                # 主菜单工具（推荐入口）
│   ├── init-update.sh         # 初始化/更新项目结构（由 note.sh 调用）
│   ├── make-main-note.sh      # 生成 main-note.tex（由 note.sh 调用）
│   ├── make-sty.sh            # 生成 latexNote.sty（由 note.sh 调用）
│   ├── auto-table.py          # CSV → LaTeX 表格转换
│   ├── clean.sh               # 清理编译辅助文件
│   └── url.sh                 # URL 转义并复制到剪贴板
├── template/                  # 模板文件目录
│   ├── cover.pdf              # 封面 PDF（可替换）
│   ├── settings.json          # VS Code 工作区设置
│   ├── note.gitignore         # Git 忽略规则
│   ├── main-note.tex          # 主笔记文件模板（可修改默认值）
│   ├── usedPackages.tex       # 导言区宏包引用
│   ├── baseSettings.tex       # 基础格式设置
│   └── myCommands.tex         # 自定义命令
└── README.md                  # 本文件
```

---

## 依赖

- **Python 3**（用于 `auto-table.py`）
- **Bash**（所有 `.sh` 脚本）
- **Git**（初始化仓库时使用）
- **XeLaTeX**（编译笔记文档）
- **macOS 剪贴板命令 `pbcopy`**（仅 `url.sh` 需要，Linux 用户可替换为 `xclip` 或 `wl-copy`）

---

## 快速开始

### 1. 赋予脚本执行权限

进入 `auto-latex-note` 根目录，为所有脚本添加可执行权限：

```bash
chmod +x script/*.sh
chmod +x script/*.py
```

### 2. 将 `note.sh` 安装到 PATH（推荐）

**只推荐将 `note.sh` 加入系统 PATH**，其它脚本无需暴露，全部通过 `note.sh` 主菜单调用。

有两种方式实现：

#### 方式一：创建符号链接（推荐）
将 `note.sh` 软链接到 `~/bin` 或 `/usr/local/bin` 等 PATH 目录：

```bash
# 确保 ~/bin 存在且在 PATH 中
mkdir -p ~/bin
export PATH="$HOME/bin:$PATH"   # 可添加到 ~/.bashrc 或 ~/.zshrc

# 创建软链接
ln -s /path/to/auto-latex-note/script/note.sh ~/bin/note
```

完成后，您可以在任意位置直接运行 `note`（或 `note.sh`，取决于链接名称）。

#### 方式二：将 `script` 目录加入 PATH（不推荐，但更简单）
如果不想创建链接，也可直接将 `script` 目录加入 PATH：

```bash
export PATH="/path/to/auto-latex-note/script:$PATH"
```

但这样会暴露所有脚本，违背“只推荐安装 note.sh”的设计初衷。

### 3. 初始化新笔记项目

进入您希望创建笔记的目录，运行：

```bash
note.sh   # 或 note（取决于链接名称）
```

在主菜单中选择 **1) 初始化工具链**，脚本会：
- 交互式询问笔记标题、作者等信息，生成 `main-note.tex`；
- 创建 `table/`、`figure/`、`chapter/`、`setting/`、`reference/` 等子目录；
- 生成样式包 `setting/latexNote.sty`；
- 复制封面、VS Code 设置、`.gitignore`；
- 初始化 Git 仓库并完成首次提交。

> **提示**：初始化后，您可以直接在项目目录下编译 `main-note.tex`（使用 XeLaTeX 编译两次）。

---

## 工具使用说明（通过 `note.sh` 主菜单）

**重要**：本工具链的**唯一推荐入口**是 `note.sh`。请勿直接调用 `init-update.sh`、`make-main-note.sh` 或 `make-sty.sh`，以免破坏项目结构或参数错误。所有功能均通过主菜单的数字编号选择运行。

`note.sh` 会自动扫描同目录下的所有脚本，解析其功能描述并显示为菜单。您只需输入数字即可运行对应工具。

### 可用的工具（菜单选项）

| 菜单编号 | 工具名称       | 功能描述                                                     |
| -------- | -------------- | ------------------------------------------------------------ |
| 1        | 初始化工具链   | 在当前目录初始化一个新笔记项目                               |
| 2        | 更新模板工具链 | 更新项目中的模板文件（`cover.pdf`、`settings.json`、`.gitignore` 和 `latexNote.sty`） |
| 3+       | 其他脚本       | 如 `auto-table.py`、`clean.sh`、`url.sh` 等（按字母顺序排列） |

---

## 各工具功能速览

### `auto-table.py` – CSV 转 LaTeX 表格

自动将 `table/Input/` 文件夹中的**唯一** CSV 文件转换为 `xltabular` 表格，并输出到 `table/Output/<哈希>/` 子目录，同时更新 `table/table-index.txt` 索引文件。

**使用流程**：
1. 将 UTF-8 编码的 CSV 放入 `table/Input/`（一次一个）。
2. 运行 `auto-table.py`（通过 `note.sh` 菜单选择对应编号）。
3. 终端会提示生成的 `\input` 和 `\cref` 命令，直接复制到正文即可。
4. 若要更新表格，用同名 CSV 覆盖 `Input/` 中的文件，重新运行脚本（旧文件自动归档）。

**特性**：
- 自动计算列宽比例。
- 支持分页和跨页表头重复。
- 对 LaTeX 特殊字符自动转义。

### `clean.sh` – 清理辅助文件

递归删除指定目录（默认当前目录）下所有 LaTeX 编译产生的辅助文件（`.aux`、`.log`、`.toc`、`.out`、`.bbl`、`.blg`、`.synctex.gz`、`.fdb_latexmk`、`.fls`、`.nav`、`.snm`、`.vrb`、`.bcf`、`.run.xml`）。

### `url.sh` – URL 转义并复制到剪贴板

将用户输入的 URL 转义为 LaTeX 安全格式（处理 `#`、`%`、`&`、`_`、`{`、`}`、`~`、`^` 等字符），并将结果复制到剪贴板（macOS 使用 `pbcopy`）。Linux 用户可将脚本中的 `pbcopy` 替换为 `xclip` 或 `wl-copy`。

---

## 自定义模板默认值

所有模板文件位于 `template/` 目录下，您可以根据需要修改它们，以改变初始项目的默认行为。

### 修改 `main-note.tex` 的默认标题/作者等

编辑 `template/main-note.tex`，找到 `\covertitle`、`\coverauthor`、`\coverdate` 等命令，修改大括号内的内容。这些值将在运行初始化或 `make-main-note.sh` 时作为预填选项。

### 修改样式包（宏包、页面设置、自定义命令）

样式包由 `template/` 下的三个文件合并而成：
- `usedPackages.tex` – 加载的宏包
- `baseSettings.tex` – 页面边距、字体、行距等
- `myCommands.tex` – 自定义命令和环境

直接编辑这些文件，然后通过 `note.sh` 选择 **更新模板工具链** 即可重新生成 `setting/latexNote.sty`。

### 替换封面图片

用您自己的 PDF 替换 `template/cover.pdf`，然后执行更新模板操作。

### 修改 VS Code 设置或 `note.gitignore`

编辑 `template/settings.json` 或 `template/note.gitignore`，更新模板后会自动覆盖到项目中。


---

## 为工具链添加新脚本

如果您希望扩展本工具链，添加自己的脚本，请遵循以下规范，以确保它能被 `note.sh` 主菜单正确识别和调用：

### 1. 文件命名与位置
- 将脚本放在 `script/` 目录下。
- 支持 `.sh`（Bash）和 `.py`（Python）两种格式。

### 2. 必须包含 `@description` 注释
在脚本文件头部（通常为第二行或第三行）添加如下格式的注释：
```bash
# @description: 简短描述该脚本的功能
```
或（Python）：
```python
# @description: 简短描述该脚本的功能
```
`note.sh` 会扫描所有脚本，读取该描述并在菜单中显示，方便用户了解每个工具的用途。

### 3. 支持 `-h` 或 `--help` 参数
脚本应具备帮助信息功能，当用户传入 `-h` 或 `--help` 时，打印用法说明并退出（退出码 0）。这便于用户在菜单外直接调用时获取帮助。

### 4. 参数约定
- 脚本应**接受一个可选的目标目录作为参数**（通常为第一个参数）。当未提供时，默认处理当前工作目录。
- 这允许 `note.sh` 将当前工作目录传递给脚本，确保脚本在正确的上下文中运行。

### 5. 返回值
- 成功执行时返回 `0`。
- 发生错误时返回非零值，以便 `note.sh` 可以捕获并提示用户。

### 6. 可执行权限
新脚本必须具有可执行权限（`chmod +x script/新脚本`），否则 `note.sh` 无法运行它。

### 示例模板（Bash）
```bash
#!/bin/bash

# @description: 示例脚本，演示如何符合规范

RESET='\033[0m'
CYAN='\033[36m'

usage() {
    printf '%b\n' "${CYAN}用法:${RESET} $(basename "$0") [目标目录]"
    printf '示例脚本描述\n'
    exit 0
}

# 处理帮助参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

# 确定目标目录
TARGET_DIR="${1:-.}"
# 后续脚本逻辑...
```

按照上述规范编写的新脚本会自动出现在 `note.sh` 菜单中，并享受统一的调用体验。

---

## 常见问题

**Q：能否在 Windows 上使用？** 
A：建议使用 WSL2 或 Git Bash。`url.sh` 中的剪贴板命令需要适配（如 `clip`）。

**Q：编译笔记需要什么命令？** 
A：推荐 `xelatex` 编译两次，相关命令设置已经定义在`.vscode/settings.json`中。

**Q：如何添加新章节？** 
A：在 `chapter/` 目录创建 `chapterX.tex`，并在 `main-note.tex` 中用 `\include{chapter/chapterX}` 引入。

**Q：表格索引文件 `table-index.txt` 有什么作用？** 
A：它集中记录了所有已生成表格的 `\input` 和 `\cref` 命令，方便直接复制引用代码。

**Q：我修改了模板，如何同步到已有项目？** 
A：在项目目录运行 `note.sh`，选择 **2) 更新模板工具链**，或直接执行 `init-update.sh -u .`（建议通过菜单）。

---

## 贡献与许可

本项目基于MIT License。

---

**Happy TeXing!** 🚀