# Claude Code 一键安装脚本 (Windows PowerShell)
# 官方 Native Install 方式 - 无需 Node.js / npm
# 对应官方命令: irm https://claude.ai/install.ps1 | iex

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ======================== 颜色输出 ========================
function Write-Success($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Info($msg)   { Write-Host "[*]  $msg" -ForegroundColor Cyan }
function Write-Warn($msg)   { Write-Host "[!]  $msg" -ForegroundColor Yellow }
function Write-Error2($msg) { Write-Host "[X]  $msg" -ForegroundColor Red }

# ======================== 欢迎 ========================
Write-Host ""
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "|     Claude Code 一键安装 (Native Install)    |" -ForegroundColor Cyan
Write-Host "|     官方方式 - 无需 Node.js / npm            |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ======================== 检查 Git ========================
$gitVer = git --version 2>$null
if ($gitVer) {
    Write-Success "Git 已安装: $gitVer"
} else {
    Write-Warn "未检测到 Git for Windows"
    Write-Host ""
    Write-Host "  Claude Code 需要 Git for Windows 才能在 Windows 上运行"
    Write-Host "  请先安装 Git:" -ForegroundColor Yellow
    Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
    Write-Host ""
    $installGit = Read-Host "是否通过 winget 安装 Git? (y/n)"
    if ($installGit -eq 'y') {
        Write-Info "正在安装 Git..."
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Success "Git 已安装"
    } else {
        Write-Error2 "Git 是必需依赖，请安装后重新运行脚本"
        exit 1
    }
}

# ======================== 安装路径 ========================
$InstallDir = Join-Path $env:USERPROFILE ".local\bin"
$ClaudeExe  = Join-Path $InstallDir "claude.exe"
$ShareDir   = Join-Path $env:USERPROFILE ".local\share\claude"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ======================== 检查已安装 ========================
$alreadyInstalled = $false
$installedVersion = $null
if (Test-Path $ClaudeExe) {
    try {
        $installedVersion = & $ClaudeExe --version 2>$null
        $alreadyInstalled = $true
    } catch {}
}

if ($alreadyInstalled) {
    Write-Success "已安装 Claude Code ($installedVersion)"
    Write-Host ""
    Write-Host "  已安装路径: " -NoNewline
    Write-Host $ClaudeExe -ForegroundColor Cyan
    Write-Host "  安装路径: " -NoNewline
    Write-Host $InstallDir -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [U] 更新到最新版本" -ForegroundColor Cyan
    Write-Host "  [R] 完全卸载" -ForegroundColor Yellow
    Write-Host "  [C] 跳过安装" -ForegroundColor Green
    Write-Host ""
    $action = Read-Host "请选择操作 (u/r/c)"
    switch ($action.ToLower()) {
        "u" {
            Write-Info "正在更新到最新版..."
            Remove-Item -Path $ClaudeExe -Force
            # fall through to download new
        }
        "r" {
            Write-Info "正在卸载..."
            Remove-Item -Path $ClaudeExe -Force -ErrorAction SilentlyContinue
            if (Test-Path $ShareDir) {
                Remove-Item -Path $ShareDir -Recurse -Force -ErrorAction SilentlyContinue
            }
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($currentPath -match [regex]::Escape($InstallDir)) {
                $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
                Write-Success "已从 PATH 移除安装目录"
            }
            Write-Success "卸载完成"
            exit 0
        }
        default {
            Write-Info "跳过安装"
            exit 0
        }
    }
}

# ======================== 下载 claude.exe ========================
Write-Info "正在下载 Claude Code..."
$downloadUrl = "https://claude.ai/install/windows/claude.exe"
$tempFile    = Join-Path $env:TEMP "claude-install.exe"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Warn "官方下载失败 ($($_.Exception.Message))"
    Write-Host ""
    Write-Host "  可能原因:" -ForegroundColor Yellow
    Write-Host "  1. 网络被地区限制（需要代理）"
    Write-Host "  2. 防火墙/杀毒软件拦截"
    Write-Host ""
    Write-Host "  如果设置了 HTTP 代理，请确认环境变量正确:"
    Write-Host "  `$env:HTTP_PROXY  = `"http://127.0.0.1:端口`""
    Write-Host "  `$env:HTTPS_PROXY = `"http://127.0.0.1:端口`""
    Write-Host ""
    $manual = Read-Host "是否指定本地已下载的 claude.exe 路径？直接回车则退出"
    if ([string]::IsNullOrWhiteSpace($manual)) { exit 1 }
    if (Test-Path $manual) {
        Copy-Item -Path $manual -Destination $ClaudeExe -Force
    } else {
        Write-Error2 "文件不存在: $manual"
        exit 1
    }
}

if (Test-Path $tempFile) {
    Write-Info "正在安装到 $InstallDir ..."
    Move-Item -Path $tempFile -Destination $ClaudeExe -Force
}

if (-not (Test-Path $ClaudeExe)) {
    Write-Error2 "安装可执行文件未出现在预期位置"
    exit 1
}

# ======================== 添加到 PATH ========================
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notmatch [regex]::Escape($InstallDir)) {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    $env:Path = "$env:Path;$InstallDir"
    Write-Success "已将 $InstallDir 添加到用户 PATH"
}

# ======================== 验证安装 ========================
try {
    $ver = & $ClaudeExe --version 2>$null
    Write-Success "Claude Code 已安装: $ver"
} catch {
    Write-Warn "安装完成，但验证失败（如提示找不到命令，请将 $InstallDir 手动添加到 PATH）"
}

# ======================== 可选：配置 API 环境变量 ========================
Write-Host ""
$configureEnv = Read-Host "是否配置自定义 API 环境变量？(y/n) — 直连官方可跳过"
if ($configureEnv -eq 'y') {
    Write-Host ""
    Write-Info "配置自定义 BASE_URL（可选，直连官方请留空回车）"
    $baseUrl = Read-Host "ANTHROPIC_BASE_URL"
    Write-Host ""
    $apiKey = Read-Host "ANTHROPIC_AUTH_TOKEN (API Key, 以 sk- 开头)"

    if (-not [string]::IsNullOrWhiteSpace($apiKey)) {
        if (-not [string]::IsNullOrWhiteSpace($baseUrl)) {
            [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $baseUrl, "User")
            $env:ANTHROPIC_BASE_URL = $baseUrl
        }
        [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $apiKey, "User")
        $env:ANTHROPIC_AUTH_TOKEN = $apiKey
        # 使用 AUTH_TOKEN 方式时清除 API_KEY 避免冲突
        [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "", "User")
        $env:ANTHROPIC_API_KEY = ""
        Write-Success "环境变量已配置，重启终端后生效"
    } else {
        Write-Warn "未提供 API Key，已跳过"
    }
}

# ======================== 完成 ========================
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  安装完成" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  启动: " -NoNewline
Write-Host "claude" -ForegroundColor Cyan
Write-Host "  版本: " -NoNewline
Write-Host "claude --version" -ForegroundColor Cyan
Write-Host "  更新: " -NoNewline
Write-Host "claude update" -ForegroundColor Cyan
Write-Host "  登录: " -NoNewline
Write-Host "claude login" -ForegroundColor Cyan
Write-Host "  登出: " -NoNewline
Write-Host "claude logout" -ForegroundColor Cyan
Write-Host ""
Write-Host "  权限切换: 运行时按 " -NoNewline
Write-Host "Shift+Tab" -ForegroundColor Cyan -NoNewline
Write-Host " 切换权限模式"
Write-Host ""
Write-Host "  卸载: 重新运行本脚本选择卸载，或手动删除:"
Write-Host "  Remove-Item -Path `"$ClaudeExe`" -Force"
Write-Host "  Remove-Item -Path `"$ShareDir`" -Recurse -Force"
Write-Host ""
