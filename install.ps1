# Claude Code 一键安装脚本 (Windows PowerShell)
# 官方 Native Install 方式 - 无需 Node.js / npm
# 一行命令下载即运行:
#   iex (irm https://gh-proxy.com/https://raw.githubusercontent.com/Daiyimo/claude-code-installer/main/install.ps1)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-OK($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-INFO($msg) { Write-Host "[*]  $msg" -ForegroundColor Cyan }
function Write-WARN($msg) { Write-Host "[!]  $msg" -ForegroundColor Yellow }

# ======================== 欢迎 ========================
Write-Host ""
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "|     Claude Code 一键安装 (Native Install)    |" -ForegroundColor Cyan
Write-Host "|     官方方式 - 无需 Node.js / npm            |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ======================== 确保 Git ========================
$gitVer = git --version 2>$null
if (-not $gitVer) {
    Write-WARN "未检测到 Git for Windows，正在通过 winget 安装..."
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements 2>$null | Out-Null
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $gitVer = git --version 2>$null
    if ($gitVer) { Write-OK "Git 已安装: $gitVer" }
} else {
    Write-OK "Git 已安装: $gitVer"
}

# ======================== 安装路径 ========================
$InstallDir = Join-Path $env:USERPROFILE ".local\bin"
$ClaudeExe  = Join-Path $InstallDir "claude.exe"
$ShareDir   = Join-Path $env:USERPROFILE ".local\share\claude"
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# ======================== 检查已安装 ========================
$installedVersion = & $ClaudeExe --version 2>$null
if ($installedVersion) {
    Write-OK "Claude Code ($installedVersion) 已安装，跳过"
} else {
    # ======================== 下载 claude.exe ========================
    Write-INFO "正在下载 Claude Code..."
    $downloadUrl = "https://claude.ai/install/windows/claude.exe"
    $tempFile    = Join-Path $env:TEMP "claude-install.exe"

    $downloaded = $false
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
        $downloaded = $true
    } catch {
        Write-WARN "官方下载失败，跳过"
    }

    if ($downloaded) {
        Move-Item -Path $tempFile -Destination $ClaudeExe -Force
        Write-OK "已安装到 $ClaudeExe"
    }

    # 添加到 PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notmatch [regex]::Escape($InstallDir)) {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
        $env:Path = "$env:Path;$InstallDir"
    }

    # 验证
    try {
        $ver = & $ClaudeExe --version 2>$null
        Write-OK "Claude Code $ver 安装完成"
    } catch {
        Write-WARN "安装完成，验证失败（如提示找不到命令，请将 $InstallDir 添加到 PATH）"
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
Write-Host ""
Write-Host "  权限切换: 运行时按 " -NoNewline
Write-Host "Shift+Tab" -ForegroundColor Cyan -NoNewline
Write-Host " 切换权限模式"
Write-Host ""
