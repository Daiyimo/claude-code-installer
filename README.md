# Claude Code 一键安装

Claude Code 官方 Native Install 方式的一键安装脚本，支持 **Windows / Linux / macOS** 三平台。无需 Node.js 和 npm，直接下载独立可执行文件。

## 快速开始

### Windows (PowerShell)

官方直装：

```powershell
irm https://claude.ai/install.ps1 | iex
```

本仓库（国内加速）：

```powershell
iex (irm https://gh-proxy.com/https://raw.githubusercontent.com/Daiyimo/claude-code-installer/main/install.ps1)
```

> 一条命令下载即运行，脚本通过管道执行，不残留任何文件。脚本会自动检测 Git for Windows，缺失时通过 winget 静默安装。

### Linux (Bash)

官方直装：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

本仓库（国内加速）：

```bash
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/Daiyimo/claude-code-installer/main/install.sh" -o install.sh
bash install.sh
```

### macOS (Bash)

官方直装：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

本仓库（国内加速）：

```bash
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/Daiyimo/claude-code-installer/main/install_macos.sh" -o install_macos.sh
bash install_macos.sh
```

## 脚本功能

- [x] 自动检测已安装版本，重复运行时提供 **更新 / 卸载 / 跳过** 选项
- [x] 官方 Native Install 方式，无需 Node.js / npm
- [x] 自动将安装目录添加到用户 PATH
- [x] 可选配置自定义 API 环境变量（直连官方跳过即可）
- [x] 下载失败时支持指定本地已下载的 claude 文件路径
- [x] 可逆卸载，同时清理安装目录和 PATH 条目
- [x] 安装完成后显示常用命令速查

## 与原版第三方脚本的差异

| 原版问题脚本 | 本脚本 |
|---|---|
| 需 Node.js + npm 全局安装 | 官方 Native Install，零依赖 |
| 向 `$PROFILE` 注入 `--dangerously-skip-permissions` | **不修改安全设置**，保留权限确认机制 |
| 硬编码第三方 API 代理 | 用户自主选择是否配置自定义 API 地址 |
| 修改全局 npm registry | 不使用 npm，不污染全局配置 |
| 无卸载支持 | 支持可逆卸载 |

## 搭配 CC Switch 使用（推荐）

安装完成后，推荐使用 **CC Switch** 进行 API 配置和模型切换。

> **CC Switch** 是一个跨平台桌面应用，用于管理 Claude Code、Codex、Gemini CLI、OpenCode、OpenClaw 等 AI 编程工具的后端模型配置。支持一键切换 Provider、保存多套 API 配置、内置 50+ 供应商预设、统一 MCP/Skills 管理以及系统托盘即时切换。

- **GitHub**: https://github.com/farion1231/cc-switch
- **最新版本**: https://github.com/farion1231/cc-switch/releases
- **支持平台**: Windows / macOS / Linux

### 使用流程

1. 运行安装脚本，安装 Claude Code
2. 从 [CC Switch Releases](https://github.com/farion1231/cc-switch/releases) 下载对应平台的安装包
3. 安装并启动 CC Switch
4. 在 CC Switch 中选择 API 提供商、填入 API Key
5. 一键导入配置到 Claude Code，即开即用

## 常用命令

安装完成后，可以使用以下命令：

| 命令 | 说明 |
|---|---|
| `claude` | 启动 Claude Code |
| `claude --version` | 查看版本 |
| `claude update` | 更新到最新版本 |
| `claude login` | 登录官方账号 |
| `claude logout` | 登出 |
| `claude --dangerously-skip-permissions` | 跳过权限确认（谨慎使用） |

> 运行时按 **Shift+Tab** 可切换权限模式，无需频繁确认操作。

## 卸载

重新运行安装脚本选择 **卸载**，或手动删除：

**Windows:**
```powershell
Remove-Item -Path "$env:USERPROFILE\.local\bin\claude.exe" -Force
Remove-Item -Path "$env:USERPROFILE\.local\share\claude" -Recurse -Force
```

**Linux / macOS:**
```bash
rm -f "$HOME/.local/bin/claude"
rm -rf "$HOME/.local/share/claude"
```

## 项目结构

```
├── install.ps1        # Windows 安装脚本 (PowerShell)
├── install.sh         # Linux 安装脚本 (Bash)
├── install_macos.sh   # macOS 安装脚本 (Bash)
└── README.md          # 说明文档
```

## 官方文档

- Claude Code Docs: https://code.claude.com/docs/en/setup
