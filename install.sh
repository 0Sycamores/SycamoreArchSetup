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
    INFO="${BOLD_BLUE}"
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

# 检查 Root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要 Root 权限。 请使用 ${BOLD_WHITE}sudo${RESET} 运行或切换到 ${BOLD_WHITE}root${RESET} 用户。"
        exit 1
    fi
}

# 打印系统信息
system_information() {
    local distro="Unknown"
    
    # 尝试获取 Linux 发行版名称
    if [ -f /etc/os-release ]; then
        distro=$(grep -E "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    elif [ -f /etc/issue ]; then
        distro=$(head -n 1 /etc/issue)
    fi

    # 获取 CPU 型号
    local cpu_info=""
    if [ -f /proc/cpuinfo ]; then
        cpu_info=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
    fi

    # 获取内存信息
    local mem_total=""
    local mem_used=""
    local mem_available=""
    local swap_total=""
    local swap_used=""
    if command -v free &> /dev/null; then
        mem_total=$(free -h | awk '/^Mem:/ {print $2}')
        mem_used=$(free -h | awk '/^Mem:/ {print $3}')
        mem_available=$(free -h | awk '/^Mem:/ {print $7}')
        swap_total=$(free -h | awk '/^Swap:/ {print $2}')
        swap_used=$(free -h | awk '/^Swap:/ {print $3}')
    fi

    # 获取硬盘信息
    local disk_used=""
    local disk_total=""
    local fs_type=""
    if command -v df &> /dev/null; then
        disk_used=$(df -h / | awk 'NR==2 {print $3}')
        disk_total=$(df -h / | awk 'NR==2 {print $2}')
        fs_type=$(df -T / | awk 'NR==2 {print $2}')
    fi

    # 打印系统信息
    echo -e "${INFO}[SYSTEM]${RESET}     操作系统信息"
    echo -e "  ${BOLD_WHITE}OS:${RESET}        ${distro}"
    echo -e "  ${BOLD_WHITE}Kernel:${RESET}    $(uname -r)"
    echo -e "  ${BOLD_WHITE}Arch:${RESET}      $(uname -m)"
    echo -e "  ${BOLD_WHITE}CPU:${RESET}       ${cpu_info}"
    echo -e "  ${BOLD_WHITE}Memory:${RESET}    ${mem_used} / ${mem_total}  Swap: ${swap_used} / ${swap_total}"
    echo -e "  ${BOLD_WHITE}Disk:${RESET}      ${disk_used} / ${disk_total} (${fs_type})"
    echo -e "  ${BOLD_WHITE}User:${RESET}      $(whoami)@$(hostname 2>/dev/null || echo "")"
    echo ""
}

# 检查系统要求
check_system_requirements() {
    info "正在检查系统环境..."

    # 1. 检查是否为 Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "检测到非 Arch Linux 系统。停止安装。"
        exit 1
    fi

    # 2. 检查根文件系统是否为 Btrfs
    local fs_type=$(df -T / | awk 'NR==2 {print $2}')
    if [[ "$fs_type" != "btrfs" ]]; then
        error "根文件系统不是 Btrfs (检测到: ${fs_type}), 停止安装。"
        exit 1
    fi

    # 3. 检查磁盘剩余空间 (>10GB)
    local available_kb=$(df -k / | awk 'NR==2 {print $4}')
    if [[ $available_kb -lt 10485760 ]]; then
        error "磁盘空间不足。需要至少 10GB 可用空间。"
        exit 1
    fi

    success "系统环境检查通过。"
}

# 打印信息
info() {
    echo -e "${INFO}[INFO] ${RESET} $*"
}

# 打印成功消息
success() {
    echo -e "${SUCCESS}[SUCCESS]${RESET} $*"
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
    show_banner
    check_root
    system_information
    check_system_requirements

    success "Setup completed successfully!"
}

# 捕获 Ctrl+C
trap 'echo -e "\n${RED}[!] Script interrupted by user.${RESET}"; exit 1' SIGINT

# 执行主函数
main "$@"

## 