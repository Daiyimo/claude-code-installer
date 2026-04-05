#!/usr/bin/env bash
# Claude Code 一键安装脚本 (Linux)
# 官方 Native Install - 对应官方命令: curl -fsSL https://claude.ai/install.sh | bash

set -e

# ======================== 颜色输出 ========================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success() { echo -e "[${GREEN}OK${NC}] $1"; }
info()    { echo -e "[${CYAN}*${NC}]  $1"; }
warn()    { echo -e "[${YELLOW}!${NC}]  $1"; }
error()   { echo -e "[${RED}X${NC}]  $1"; }

# ======================== 欢迎 ========================
echo ""
echo -e "+----------------------------------------------+"
echo -e "|     Claude Code 一键安装 (Native Install)    |"
echo -e "|     Linux - 无需 Node.js / npm               |"
echo -e "+----------------------------------------------+"
echo ""

# ======================== 安装路径 ========================
INSTALL_DIR="$HOME/.local/bin"
CLAUDE_EXE="$INSTALL_DIR/claude"
SHARE_DIR="$HOME/.local/share/claude"

mkdir -p "$INSTALL_DIR"

# ======================== 检查已安装 ========================
ALREADY_INSTALLED=false
INSTALLED_VERSION=""
if [ -f "$CLAUDE_EXE" ]; then
    INSTALLED_VERSION=$("$CLAUDE_EXE" --version 2>/dev/null || true)
    if [ -n "$INSTALLED_VERSION" ]; then
        ALREADY_INSTALLED=true
    fi
fi

if $ALREADY_INSTALLED; then
    success "已安装 Claude Code ($INSTALLED_VERSION)"
    echo ""
    echo "  已安装路径: $CLAUDE_EXE"
    echo ""
    echo -e "  [U] 更新到最新版本"
    echo -e "  [R] 完全卸载"
    echo -e "  [C] 跳过安装"
    echo ""
    read -p "请选择操作 (u/r/c): " ACTION
    case "$(echo "$ACTION" | tr '[:upper:]' '[:lower:]')" in
        u)
            info "正在更新到最新版本..."
            rm -f "$CLAUDE_EXE"
            ;;
        r)
            info "正在卸载..."
            rm -f "$CLAUDE_EXE"
            rm -rf "$SHARE_DIR"
            success "卸载完成"
            exit 0
            ;;
        *)
            info "跳过安装"
            exit 0
            ;;
    esac
fi

# ======================== 下载 claude ========================
info "正在下载 Claude Code..."
DOWNLOAD_URL="https://claude.ai/install/linux/claude"
TEMP_FILE="/tmp/claude-install"

if curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
    chmod +x "$TEMP_FILE"
    mv -f "$TEMP_FILE" "$CLAUDE_EXE"
else
    warn "官方下载失败"
    echo ""
    echo "  可能原因: 网络被地区限制（需要代理）"
    echo "  如果设置了 HTTP 代理，请确认环境变量正确:"
    echo "  export http_proxy=http://127.0.0.1:端口"
    echo "  export https_proxy=http://127.0.0.1:端口"
    echo ""

    read -p "是否指定本地已下载的 claude 路径？直接回车则退出: " MANUAL
    if [ -z "$MANUAL" ]; then exit 1; fi
    if [ ! -f "$MANUAL" ]; then error "文件不存在: $MANUAL"; exit 1; fi
    cp -f "$MANUAL" "$CLAUDE_EXE"
    chmod +x "$CLAUDE_EXE"
fi

# ======================== 确保 PATH ========================
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "" >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$INSTALL_DIR:$PATH"
    success "已将 $INSTALL_DIR 添加到 PATH (~/.bashrc)"
fi

# ======================== 验证 ========================
if VER=$("$CLAUDE_EXE" --version 2>/dev/null); then
    success "Claude Code 已安装: $VER"
else
    warn "安装完成，但验证失败（如提示找不到命令，请将 $INSTALL_DIR 添加到 PATH）"
fi

# ======================== 可选配置 ========================
echo ""
read -p "是否配置自定义 API 环境变量？(y/n) — 直连官方可跳过: " CONFIGure
if [ "$CONFIGure" = "y" ]; then
    echo ""
    info "配置自定义 BASE_URL（可选，直连官方请留空）"
    read -p "ANTHROPIC_BASE_URL: " BASE_URL
    echo ""
    read -p "ANTHROPIC_AUTH_TOKEN (API Key, sk-开头): " API_KEY

    if [ -n "$API_KEY" ]; then
        [ -n "$BASE_URL" ] && export ANTHROPIC_BASE_URL="$BASE_URL"
        export ANTHROPIC_AUTH_TOKEN="$API_KEY"
        export ANTHROPIC_API_KEY=""

        echo "" >> "$HOME/.bashrc"
        [ -n "$BASE_URL" ] && echo "export ANTHROPIC_BASE_URL=\"$BASE_URL\"" >> "$HOME/.bashrc"
        echo "export ANTHROPIC_AUTH_TOKEN=\"$API_KEY\"" >> "$HOME/.bashrc"
        echo "export ANTHROPIC_API_KEY=\"\"" >> "$HOME/.bashrc"
        success "环境变量已配置，新终端 session 后生效"
    else
        warn "未提供 API Key，已跳过"
    fi
fi

# ======================== 完成 ========================
echo ""
echo "=============================================="
echo "  安装完成"
echo "=============================================="
echo ""
echo -e "  启动:  ${CYAN}claude${NC}"
echo -e "  版本:  ${CYAN}claude --version${NC}"
echo -e "  更新:  ${CYAN}claude update${NC}"
echo -e "  登录:  ${CYAN}claude login${NC}"
echo -e "  登出:  ${CYAN}claude logout${NC}"
echo ""
echo "  权限切换: 运行时按 Shift+Tab 切换权限模式"
echo ""
echo "  卸载: 重新运行本脚本选择卸载，或手动删除:"
echo "  rm -f \"$CLAUDE_EXE\""
echo "  rm -rf \"$SHARE_DIR\""
echo ""
