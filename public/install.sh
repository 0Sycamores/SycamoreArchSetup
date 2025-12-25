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
AUTO_INSTALL=false
# 开发模式通过环境变量 DEV_MODE=1 启用
DEV_MODE="${DEV_MODE:-0}"

# 进度记录相关
PROGRESS_DIR="/tmp/sycamore-setup"
PROGRESS_FILE="${PROGRESS_DIR}/progress"


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
    HEADER="${BOLD_MAGENTA}"
    PROMPT="${BOLD_CYAN}"
else
    # 如果不支持颜色，禁用所有颜色代码
    RESET='' BLACK='' RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE=''
    BOLD_BLACK='' BOLD_RED='' BOLD_GREEN='' BOLD_YELLOW='' BOLD_BLUE='' BOLD_MAGENTA='' BOLD_CYAN='' BOLD_WHITE=''
    BG_BLACK='' BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE='' BG_MAGENTA='' BG_CYAN='' BG_WHITE=''
    BOLD='' DIM='' UNDERLINE='' BLINK='' REVERSE='' HIDDEN=''
    INFO='' SUCCESS='' WARNING='' ERROR='' DEBUG='' HEADER='' PROMPT=''
fi


# 打印信息
info() {
    echo -e "${INFO}[   INFO]${RESET} $*"
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
    echo -e "${ERROR}[  ERROR]${RESET} $*" >&2
}

# 打印调试信息
debug() {
    if [[ "${DEBUG_MODE:-0}" == "1" ]]; then
        echo -e "${DEBUG}[  DEBUG]${RESET} $*"
    fi
}

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
    print_section_title "Privilege Check"
    
    if [[ $EUID -ne 0 ]]; then
        error "This script requires root privileges. Please run with ${BOLD_WHITE}sudo${RESET} or switch to ${BOLD_WHITE}root${RESET} user."
        exit 1
    fi
    
    success "Running as root"
    echo ""
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
   
    # 获取主机名
    local hostname_val=""
    if [[ -f /etc/hostname ]]; then
        hostname_val=$(cat /etc/hostname 2>/dev/null | tr -d '[:space:]')
    elif command -v hostnamectl &> /dev/null; then
        hostname_val=$(hostnamectl --static 2>/dev/null)
    fi

    # 打印系统信息
    echo -e "${INFO}[ SYSTEM]${RESET} System Information"
    echo -e "  ${BOLD_WHITE}OS:${RESET}        ${distro}"
    echo -e "  ${BOLD_WHITE}Kernel:${RESET}    $(uname -r)"
    echo -e "  ${BOLD_WHITE}Arch:${RESET}      $(uname -m)"
    echo -e "  ${BOLD_WHITE}CPU:${RESET}       ${cpu_info}"
    echo -e "  ${BOLD_WHITE}Memory:${RESET}    ${mem_used} / ${mem_total}  Swap: ${swap_used} / ${swap_total}"
    echo -e "  ${BOLD_WHITE}Disk:${RESET}      ${disk_used} / ${disk_total} (${fs_type})"
    echo -e "  ${BOLD_WHITE}User:${RESET}      $(whoami)@${hostname_val:-unknown}"
    echo ""
}

# 检查系统要求
check_system_requirements() {
    print_section_title "Check System Requirements"

    if [[ "${DEV_MODE}" == "1" ]]; then
        warn "Running in DEV MODE - system checks will be skipped on failure"
    fi
    
    # 1. 检查是否为 Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        if [[ "${DEV_MODE}" == "1" ]]; then
            warn "Non-Arch Linux system detected. ${DIM}(Skipped in dev mode)${RESET}"
        else
            error "Non-Arch Linux system detected. Installation stopped."
            exit 1
        fi
    fi

    # 2. 检查根文件系统是否为 Btrfs
    local fs_type=$(df -T / | awk 'NR==2 {print $2}')
    if [[ "$fs_type" != "btrfs" ]]; then
        if [[ "${DEV_MODE}" == "1" ]]; then
            warn "Root filesystem is not Btrfs (detected: ${fs_type}). ${DIM}(Skipped in dev mode)${RESET}"
        else
            error "Root filesystem is not Btrfs (detected: ${fs_type}). Installation stopped."
            exit 1
        fi
    fi

    # 3. 检查磁盘剩余空间 (>10GB)
    local available_kb=$(df -k / | awk 'NR==2 {print $4}')
    if [[ $available_kb -lt 10485760 ]]; then
        if [[ "${DEV_MODE}" == "1" ]]; then
            warn "Insufficient disk space. ${DIM}(Skipped in dev mode)${RESET}"
        else
            error "Insufficient disk space. At least 10GB of available space is required."
            exit 1
        fi
    fi

    success "System checks passed."
    echo ""
}


# 打印章节标题
# 用法: print_section_title "Section Title"
print_section_title() {
    local title="$1"
    echo -e "${HEADER}[SECTION]${RESET} ${BOLD_WHITE}${title}${RESET}"
}

# 执行命令并限制日志输出
# 用法: run_command "command" ["description"]
# 示例: run_command "pacman -Syu --noconfirm" "Updating system packages"
run_command() {
    local cmd="$1"
    local description="${2:-Executing command}"
    local max_lines=5
    local tmp_output="/tmp/sycamore_cmd_$$.log"
    local line_count=0
    local buffer=()
    
    info "${description}..."
    debug "Command: ${cmd}"
    
    # 清空临时文件
    > "${tmp_output}"
    
    # 执行命令并捕获输出
    {
        eval "${cmd}" 2>&1 | while IFS= read -r line; do
            # 保存到临时文件
            echo "${line}" >> "${tmp_output}"
            
            # 更新缓冲区（保持最后 max_lines 行）
            buffer+=("${line}")
            if [[ ${#buffer[@]} -gt ${max_lines} ]]; then
                buffer=("${buffer[@]:1}")
            fi
            
            # 清除之前的输出行
            if [[ ${line_count} -gt 0 ]]; then
                for ((i=0; i<line_count; i++)); do
                    echo -ne "\033[1A\033[2K"
                done
            fi
            
            # 显示缓冲区内容
            line_count=${#buffer[@]}
            for output_line in "${buffer[@]}"; do
                echo -e "${DIM}  │ ${output_line}${RESET}"
            done
        done
        
        # 返回命令的退出状态
        return ${PIPESTATUS[0]}
    }
    
    local exit_code=$?
    
    # 清除最后显示的行
    if [[ ${line_count} -gt 0 ]]; then
        for ((i=0; i<line_count; i++)); do
            echo -ne "\033[1A\033[2K"
        done
    fi
    
    if [[ ${exit_code} -eq 0 ]]; then
        success "${description} completed"
    else
        error "${description} failed (exit code: ${exit_code})"
        
        # 显示错误日志的最后10行
        warn "Last 10 lines of output:"
        tail -n 10 "${tmp_output}" | while IFS= read -r line; do
            echo -e "${DIM}  │ ${line}${RESET}"
        done
        
        # 询问是否查看完整日志
        if [[ "${AUTO_INSTALL}" != "true" ]]; then
            echo ""
            read -p "$(echo -e "${PROMPT}View full log? [y/N]:${RESET} ")" view_log
            if [[ "${view_log}" =~ ^[Yy]$ ]]; then
                less "${tmp_output}"
            fi
        fi
    fi
    
    # 清理临时文件
    rm -f "${tmp_output}"
    
    return ${exit_code}
} 

# 询问用户是否全自动安装
prompt_auto_install() {
    print_section_title "Installation Mode Selection"
    
    while true; do
        read -p "$(echo -e "${PROMPT}Enable automatic installation? [Y/n]:${RESET} ")" choice
        # 默认选择自动安装 (Yes)
        choice=${choice:-y}
        case $choice in
            y|Y|yes|YES|"")
                AUTO_INSTALL=true
                success "Automatic installation mode selected"
                echo ""
                break
                ;;
            n|N|no|NO)
                AUTO_INSTALL=false
                success "Interactive installation mode selected"
                echo ""
                break
                ;;
            *)
                error "Invalid option. Please enter Y or N"
                ;;
        esac
    done
}

# 更新镜像源为最快的源
update_mirrorlist() {
    print_section_title "Mirror List Optimization"
    
    local do_update=false
    
    # 自动安装模式直接执行
    if [[ "${AUTO_INSTALL}" == "true" ]]; then
        info "Auto-install mode: updating mirror list automatically"
        do_update=true
    else
        # 交互式询问
        while true; do
            read -p "$(echo -e "${PROMPT}Update mirror list to fastest servers? [Y/n]:${RESET} ")" choice
            # 默认选择是 (Yes)
            choice=${choice:-y}
            case $choice in
                y|Y|yes|YES|"")
                    do_update=true
                    break
                    ;;
                n|N|no|NO)
                    info "Skipping mirror list update"
                    echo ""
                    return 0
                    ;;
                *)
                    error "Invalid option. Please enter Y or N"
                    ;;
            esac
        done
    fi
    
    # 执行更新
    if [[ "${do_update}" == "true" ]]; then
        info "Updating mirror list to fastest servers..."
        
        # 检查 reflector 是否安装
        if ! command -v reflector &> /dev/null; then
            warn "reflector not found. Installing reflector..."
            run_command "pacman -Sy --noconfirm reflector" "Installing reflector" || {
                error "Failed to install reflector"
                return 1
            }
        fi
        
        # 检测国家代码
        local country_code=""
        local current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "")
        
        if [[ "${current_tz}" == "Asia/Shanghai" ]]; then
            # 时区为 Asia/Shanghai，使用中国源
            info "Timezone detected: ${current_tz}, using China mirrors"
            country_code="cn"
        else
            # 尝试通过 IP 获取国家代码
            info "Detecting location via IP..."
            local detected_code=$(curl -s --max-time 2 https://ipinfo.io/country 2>/dev/null | tr -d '[:space:]')
            
            if [[ -n "${detected_code}" && "${detected_code}" =~ ^[A-Z]{2}$ ]]; then
                info "Country detected: ${detected_code}, using local mirrors"
                country_code="${detected_code,,}"
            else
                warn "Unable to detect location, using global mirrors"
            fi
        fi
        
        # 构建 reflector 命令（使用 http/https 协议避免 rsync 警告）
        local reflector_cmd="reflector -a 12 -f 10 --protocol http,https --sort score --save /etc/pacman.d/mirrorlist --verbose"
        [[ -n "${country_code}" ]] && reflector_cmd+=" -c ${country_code}"
        
        # 执行 reflector 命令
        run_command "${reflector_cmd}" "Updating mirror list" || {
            error "Failed to update mirror list"
            return 1
        }
        
        success "Mirror list optimization completed"
        echo ""
    fi
}

# 更新系统
update_system() {
    print_section_title "System Update"
    
    local do_update=false
    
    # 自动安装模式直接执行
    if [[ "${AUTO_INSTALL}" == "true" ]]; then
        info "Auto-install mode: updating system automatically"
        do_update=true
    else
        # 交互式询问
        while true; do
            read -p "$(echo -e "${PROMPT}Update system packages? [Y/n]:${RESET} ")" choice
            # 默认选择是 (Yes)
            choice=${choice:-y}
            case $choice in
                y|Y|yes|YES|"")
                    do_update=true
                    break
                    ;;
                n|N|no|NO)
                    info "Skipping system update"
                    echo ""
                    return 0
                    ;;
                *)
                    error "Invalid option. Please enter Y or N"
                    ;;
            esac
        done
    fi
    
    # 执行更新
    if [[ "${do_update}" == "true" ]]; then
        run_command "pacman -Syu --noconfirm" "Updating system packages" || {
            error "Failed to update system"
            return 1
        }
        
        success "System update completed"
        echo ""
    fi
}

# ==============================================================================
# 进度记录系统
# ==============================================================================

# 初始化进度记录系统
init_progress() {
    # 创建进度目录
    if [[ ! -d "${PROGRESS_DIR}" ]]; then
        mkdir -p "${PROGRESS_DIR}"
    fi
    
    # 创建进度文件
    if [[ ! -f "${PROGRESS_FILE}" ]]; then
        touch "${PROGRESS_FILE}"
    fi
}

# 清理进度文件
cleanup_progress() {
    if [[ -d "${PROGRESS_DIR}" ]]; then
        rm -rf "${PROGRESS_DIR}"
        debug "Progress directory cleaned up"
    fi
}

# 检查步骤是否已完成
is_step_completed() {
    local step_name="$1"
    grep -qx "${step_name}" "${PROGRESS_FILE}" 2>/dev/null
}

# 标记步骤为已完成
mark_step_completed() {
    local step_name="$1"
    
    # 避免重复记录
    if ! is_step_completed "${step_name}"; then
        echo "${step_name}" >> "${PROGRESS_FILE}"
        debug "Marked step '${step_name}' as completed"
    fi
}

# 重置进度
reset_progress() {
    if [[ -f "${PROGRESS_FILE}" ]]; then
        > "${PROGRESS_FILE}"
        success "Progress has been reset"
    fi
}

# 获取已完成的步骤数量
get_completed_steps_count() {
    if [[ -f "${PROGRESS_FILE}" ]]; then
        wc -l < "${PROGRESS_FILE}" 2>/dev/null | tr -d ' '
    else
        echo "0"
    fi
}

# 显示已完成的步骤
show_completed_steps() {
    if [[ -f "${PROGRESS_FILE}" ]] && [[ -s "${PROGRESS_FILE}" ]]; then
        info "Completed steps from previous run:"
        while IFS= read -r step; do
            echo -e "  ${SUCCESS}✓${RESET} ${step}"
        done < "${PROGRESS_FILE}"
    fi
}

# 检查是否有未完成的安装进度，并询问用户是否继续
check_previous_progress() {
    init_progress
    
    local completed_count=$(get_completed_steps_count)
    
    if [[ ${completed_count} -gt 0 ]]; then
        print_section_title "Previous Installation Detected"
        
        info "Found ${completed_count} completed step(s) from previous installation"
        show_completed_steps
        echo ""
        
        if [[ "${AUTO_INSTALL}" == "true" ]]; then
            info "Auto-install mode: continuing from previous progress"
            return 0
        fi
        
        while true; do
            echo -e "${PROMPT}How would you like to proceed?${RESET}"
            echo -e "  ${BOLD_WHITE}[C]${RESET} Continue from where you left off"
            echo -e "  ${BOLD_WHITE}[R]${RESET} Reset and start fresh"
            echo -e "  ${BOLD_WHITE}[Q]${RESET} Quit"
            read -p "$(echo -e "${PROMPT}Your choice [C/r/q]:${RESET} ")" choice
            
            choice=${choice:-c}
            case ${choice} in
                c|C|continue|"")
                    info "Continuing from previous progress..."
                    echo ""
                    return 0
                    ;;
                r|R|reset)
                    reset_progress
                    echo ""
                    return 0
                    ;;
                q|Q|quit)
                    info "Installation cancelled by user"
                    exit 0
                    ;;
                *)
                    error "Invalid option. Please enter C, R, or Q"
                    ;;
            esac
        done
    fi
}

# 运行带进度记录的步骤
# 用法: run_step "step_name" "function_name" ["description"]
# 返回值: 0 表示成功（包括跳过），1 表示失败
run_step() {
    local step_name="$1"
    local step_func="$2"
    local description="${3:-${step_name}}"
    
    # 检查是否已完成
    if is_step_completed "${step_name}"; then
        info "Skipping '${description}' ${DIM}(already completed)${RESET}"
        return 0
    fi
    
    # 执行步骤函数
    if "${step_func}"; then
        mark_step_completed "${step_name}"
        return 0
    else
        error "Step '${description}' failed"
        return 1
    fi
}

# ==============================================================================
# 主逻辑
# ==============================================================================

main() {
    show_banner
    system_information
    check_root
    check_system_requirements
    prompt_auto_install
    update_mirrorlist
    update_system

    # 初始化安装进度
    init_progress
        
    # 安装完成后自动清理进度文件
    cleanup_progress
}

# 捕获 Ctrl+C
trap 'echo -e "\n${RED}[!] Script interrupted by user.${RESET}"; exit 1' SIGINT

# 执行主函数
main "$@"

## ## ## ##