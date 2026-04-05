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
$installedVersion = $null
if (Test-Path $ClaudeExe) {
    try {
        $installedVersion = & $ClaudeExe --version 2>$null
        if ($installedVersion) {
            Write-OK "Claude Code ($installedVersion) 已安装，跳过"
            return
        }
    } catch {
        # 文件存在但无法执行，删除后重新安装
        Write-WARN "检测到损坏的安装，正在重新安装..."
        Remove-Item $ClaudeExe -Force -ErrorAction SilentlyContinue
    }
}
if (-not $installedVersion) {
    # ======================== 下载 claude.exe ========================
    Write-INFO "正在下载 Claude Code..."
    $downloadUrl = "https://claude.ai/install/windows/claude.exe"
    $tempFile    = Join-Path $env:TEMP "claude-install.exe"

    # 使用浏览器 User-Agent 避免被拒绝
    $headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    $downloaded = $false
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -Headers $headers -UseBasicParsing -ErrorAction Stop
        $downloaded = $true
    } catch {
        Write-WARN "官方下载失败: $_"
    }

    # 验证下载的文件是否为有效的可执行文件（而非HTML错误页面）
    if ($downloaded -and (Test-Path $tempFile)) {
        $fileInfo = Get-Item $tempFile
        $isValid = $false

        # 检查文件大小（正常 claude.exe 应 > 10MB）和 PE 文件头
        if ($fileInfo.Length -gt 10MB) {
            $bytes = [System.IO.File]::ReadAllBytes($tempFile)
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0x4D -and $bytes[1] -eq 0x5A) {
                $isValid = $true
            }
        }

        if (-not $isValid) {
            Write-WARN ("下载的文件无效（可能是地区限制或网络问题），文件大小: {0:N0} 字节" -f $fileInfo.Length)
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            $downloaded = $false
        }
    }
    if ($downloaded) {
        Move-Item -Path $tempFile -Destination $ClaudeExe -Force
        Write-OK "已安装到 $ClaudeExe"

        # 添加到 PATH（避免重复，处理 User PATH 为空的情况）
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $installDirInPath = $false

        # 检查当前合并后的 PATH 是否已包含安装目录
        $effectivePath = $env:Path  # 当前进程的 PATH 已经合并了 User 和 Machine
        if ($effectivePath) {
            $effectivePath -split ';' | ForEach-Object {
                if ($_.Trim().Length -gt 0 -and $_.Trim().ToLower() -eq $InstallDir.ToLower()) {
                    $installDirInPath = $true
                }
            }
        }

        if (-not $installDirInPath) {
            # 构建新的 User PATH
            if ([string]::IsNullOrWhiteSpace($userPath)) {
                # 如果 User PATH 为空，使用 Machine PATH 作为基础（如果存在）
                if ($machinePath) {
                    $newUserPath = "$machinePath;$InstallDir"
                } else {
                    $newUserPath = $InstallDir
                }
            } else {
                $newUserPath = "$userPath;$InstallDir"
            }
            [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
            # 刷新当前会话的 PATH（合并 Machine 和 User）
            $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($machinePath -and $userPath) {
                $env:Path = "$machinePath;$userPath"
            } elseif ($machinePath) {
                $env:Path = $machinePath
            } else {
                $env:Path = $userPath
            }
            Write-INFO "已添加 $InstallDir 到 PATH"
        } else {
            Write-INFO "$InstallDir 已在 PATH 中"
        }

        # 验证
        try {
            $ver = & $ClaudeExe --version 2>$null
            Write-OK "Claude Code $ver 安装完成"
        } catch {
            Write-WARN "安装完成，但验证失败。请重启 PowerShell 后运行 'claude --version' 检查"
        }
    } else {
        Write-WARN "下载失败。建议：`n        1. 使用代理/VPN 访问 claude.ai`n        2. 或手动从 https://claude.ai/install/windows/claude.exe 下载 claude.exe 到 $ClaudeExe"
        return
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
