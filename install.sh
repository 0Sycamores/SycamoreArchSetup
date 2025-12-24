#!/bin/bash
#
# 名称:     Sycamore Arch Setup
#
# 用法:     bash <(curl -sL arch.sycamore.icu)
#
# ==============================================================================

# ==============================================================================
# 全局变量
# ==============================================================================

VERSION="0.1.0"
AUTHER='Sycamore'
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# ==============================================================================
# TUI 颜色与样式定义
# ==============================================================================

# 检测终端是否支持颜色
if [[ -t 1 ]] && command -v tput &> /dev/null && tput setaf 1 &> /dev/null; then
    COLOR_SUPPORT=true
else
    COLOR_SUPPORT=false
fi

if [[ "${COLOR_SUPPORT}" == "true" ]]; then
    # 颜色重置
    RESET='\033[0m'
    
    # 前景色 - 基础颜色
    BLACK='\033[0;30m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    
    # 前景色 - 高亮/加粗颜色
    BOLD_BLACK='\033[1;30m'
    BOLD_RED='\033[1;31m'
    BOLD_GREEN='\033[1;32m'
    BOLD_YELLOW='\033[1;33m'
    BOLD_BLUE='\033[1;34m'
    BOLD_MAGENTA='\033[1;35m'
    BOLD_CYAN='\033[1;36m'
    BOLD_WHITE='\033[1;37m'
    
    # 背景色
    BG_BLACK='\033[40m'
    BG_RED='\033[41m'
    BG_GREEN='\033[42m'
    BG_YELLOW='\033[43m'
    BG_BLUE='\033[44m'
    BG_MAGENTA='\033[45m'
    BG_CYAN='\033[46m'
    BG_WHITE='\033[47m'
    
    # 文本样式
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    HIDDEN='\033[8m'
    
    # 语义化颜色
    INFO="${BOLD_WHITE}"
    SUCCESS="${BOLD_GREEN}"
    WARNING="${BOLD_YELLOW}"
    ERROR="${BOLD_RED}"
    DEBUG="${DIM}"
    HEADER="${BOLD_RED}"
    PROMPT="${BOLD_RED}"
else
    # 如果不支持颜色，禁用所有颜色代码
    RESET='' BLACK='' RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE=''
    BOLD_BLACK='' BOLD_RED='' BOLD_GREEN='' BOLD_YELLOW='' BOLD_BLUE='' BOLD_MAGENTA='' BOLD_CYAN='' BOLD_WHITE=''
    BG_BLACK='' BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE='' BG_MAGENTA='' BG_CYAN='' BG_WHITE=''
    BOLD='' DIM='' UNDERLINE='' BLINK='' REVERSE='' HIDDEN=''
    INFO='' SUCCESS='' WARNING='' ERROR='' DEBUG='' HEADER='' PROMPT=''
fi

# 打印Banner
show_banner() {
    clear
    echo -e "${BOLD_RED}"
    cat << 'EOF'
    ███████╗██╗   ██╗ ██████╗ █████╗ ███╗   ███╗ ██████╗ ██████╗ ███████╗
    ██╔════╝╚██╗ ██╔╝██╔════╝██╔══██╗████╗ ████║██╔═══██╗██╔══██╗██╔════╝
    ███████╗ ╚████╔╝ ██║     ███████║██╔████╔██║██║   ██║██████╔╝█████╗
    ╚════██║  ╚██╔╝  ██║     ██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══╝
    ███████║   ██║   ╚██████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║███████╗
    ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
EOF
    echo -e "${RESET}"
    echo -e "${DIM}    ╔═══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${DIM}    ║  ${BOLD_RED}◢◤${BOLD_WHITE} ARCH LINUX SETUP ${BOLD_RED}◥◣${RESET}${DIM}                                           ║${RESET}"
    echo -e "${DIM}    ║  ${YELLOW}▸${BOLD_YELLOW} Sycamore Edition ${YELLOW}◂${RESET}${DIM}                                             ║${RESET}"
    echo -e "${DIM}    ║  ${DIM}✧${BOLD_WHITE} Version ${VERSION} ${DIM}✧${RESET}${DIM}                                                ║${RESET}"
    echo -e "${DIM}    ╚═══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# 打印信息
info() {
    echo -e "${INFO}[INFO]${RESET} $*"
}

# 打印成功消息
success() {
    echo -e "${SUCCESS}[✓]${RESET} $*"
}

# 打印警告
warn() {
    echo -e "${WARNING}[WARNING]${RESET} $*"
}

# 打印错误
error() {
    echo -e "${ERROR}[ERROR]${RESET} $*" >&2
}

# 打印调试信息
debug() {
    if [[ "${DEBUG_MODE:-0}" == "1" ]]; then
        echo -e "${DEBUG}[DEBUG]${RESET} $*"
    fi
}

# ==============================================================================
# 主逻辑
# ==============================================================================

main() {
    # 显示 Banner
    show_banner
    success "Setup completed successfully!"
}

# 捕获 Ctrl+C
trap 'echo -e "\n${RED}[!] Script interrupted by user.${RESET}"; exit 1' SIGINT

# 执行主函数
main "$@"

