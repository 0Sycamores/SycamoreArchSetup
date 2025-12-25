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
    echo -e "${INFO}[SYSTEM]${RESET}     System Information"
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
    if [[ "${DEV_MODE}" == "1" ]]; then
        warn "Running in DEV MODE - system checks will be skipped on failure"
    fi
    
    info "Checking system requirements..."

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
}

# 打印信息
info() {
    echo -e "${INFO}[INFO]   ${RESET} $*"
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

# 打印章节标题
# 用法: print_section_title "Section Title"
print_section_title() {
    local title="$1"
    echo ""
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

# 执行 reflector 命令（专用方法，处理特殊输出）
# 用法: run_reflector "reflector_args"
# 示例: run_reflector "-a 12 -c cn -f 10 --sort score --save /etc/pacman.d/mirrorlist"
run_reflector() {
    local reflector_args="$1"
    local description="Updating mirror list"
    local tmp_output="/tmp/sycamore_reflector_$$.log"
    local max_lines=5
    
    info "${description}..."
    debug "Command: reflector ${reflector_args}"
    
    # 清空临时文件
    > "${tmp_output}"
    
    # 使用 script 命令或直接捕获，避免 reflector 的特殊输出问题
    # reflector 使用 --verbose 时会输出到 stderr，我们需要合并输出
    # 使用 stdbuf 来禁用缓冲，确保实时输出
    {
        # 后台运行 reflector 并捕获输出到临时文件
        stdbuf -oL -eL reflector ${reflector_args} > "${tmp_output}" 2>&1 &
        local reflector_pid=$!
        
        local displayed_lines=0
        
        # 循环读取输出并显示最后 max_lines 行
        while kill -0 "${reflector_pid}" 2>/dev/null; do
            local current_lines=$(wc -l < "${tmp_output}" 2>/dev/null || echo 0)
            
            if [[ ${current_lines} -gt 0 ]]; then
                # 清除之前显示的行
                if [[ ${displayed_lines} -gt 0 ]]; then
                    for ((i=0; i<displayed_lines; i++)); do
                        echo -ne "\033[1A\033[2K"
                    done
                fi
                
                # 显示最后 max_lines 行
                displayed_lines=$(( current_lines < max_lines ? current_lines : max_lines ))
                tail -n ${max_lines} "${tmp_output}" | while IFS= read -r line; do
                    echo -e "${DIM}  │ ${line}${RESET}"
                done
            fi
            
            sleep 0.3
        done
        
        # 等待 reflector 完成并获取退出码
        wait "${reflector_pid}"
        local exit_code=$?
        
        # 最后再读取一次，确保显示最终状态
        local final_lines=$(wc -l < "${tmp_output}" 2>/dev/null || echo 0)
        if [[ ${final_lines} -gt 0 ]]; then
            # 清除之前显示的行
            if [[ ${displayed_lines} -gt 0 ]]; then
                for ((i=0; i<displayed_lines; i++)); do
                    echo -ne "\033[1A\033[2K"
                done
            fi
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
        fi
        
        # 清理临时文件
        rm -f "${tmp_output}"
        
        return ${exit_code}
    }
}

# 执行命令（静默模式，不显示实时输出）
# 用法: run_command_silent "command" ["description"]
# 示例: run_command_silent "pacman -Q firefox" "Checking if firefox is installed"
run_command_silent() {
    local cmd="$1"
    local description="${2:-Executing command}"
    local tmp_output="/tmp/sycamore_cmd_silent_$$.log"
    
    debug "Running silently: ${cmd}"
    
    # 执行命令并捕获输出
    eval "${cmd}" > "${tmp_output}" 2>&1
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        debug "${description} completed (silent)"
    else
        error "${description} failed (exit code: ${exit_code})"
        
        # 显示错误日志的最后5行
        warn "Last 5 lines of output:"
        tail -n 5 "${tmp_output}" | while IFS= read -r line; do
            echo -e "${DIM}  │ ${line}${RESET}"
        done
    fi
    
    # 清理临时文件
    rm -f "${tmp_output}"
    
    return ${exit_code}
}

# 询问用户是否全自动安装
prompt_auto_install() {
    print_section_title "Installation Mode Selection"
    
    while true; do
        read -p "$(echo -e "${PROMPT}Enable automatic installation? [y/N]:${RESET} ")" choice
        # 默认选择交互式安装 (No)
        choice=${choice:-n}
        case $choice in
            y|Y|yes|YES)
                AUTO_INSTALL=true
                success "Automatic installation mode selected"
                echo ""
                break
                ;;
            n|N|no|NO|"")
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
        
        # 构建 reflector 命令
        local reflector_cmd="reflector -a 12 -f 10 --sort score --save /etc/pacman.d/mirrorlist --verbose"
        
        # 检测时区
        local current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "")
        
        if [[ "${current_tz}" == "Asia/Shanghai" ]]; then
            # 时区为 Asia/Shanghai,使用中国源
            info "Timezone detected: ${current_tz}, using China mirrors"
            reflector_cmd="reflector -a 12 -c cn -f 10 --sort score --save /etc/pacman.d/mirrorlist --verbose"
        else
            # 尝试通过 IP 获取国家代码
            info "Detecting location via IP..."
            local country_code=$(curl -s --max-time 2 https://ipinfo.io/country 2>/dev/null | tr -d '[:space:]')
            
            if [[ -n "${country_code}" && "${country_code}" =~ ^[A-Z]{2}$ ]]; then
                info "Country detected: ${country_code}, using local mirrors"
                reflector_cmd="reflector -a 12 -c ${country_code,,} -f 10 --sort score --save /etc/pacman.d/mirrorlist --verbose"
            else
                warn "Unable to detect location, using global mirrors"
            fi
        fi
        
        # 执行 reflector 命令（使用专用方法）
        # 去掉 "reflector " 前缀，只传递参数
        local reflector_args="${reflector_cmd#reflector }"
        run_reflector "${reflector_args}" || {
            error "Failed to update mirror list"
            return 1
        }
        echo ""
    fi
}

# ==============================================================================
# 主逻辑
# ==============================================================================

main() {
    show_banner
    check_root
    system_information
    # 执行系统检查(开发模式会跳过失败项)
    check_system_requirements
    # 询问用户安装模式
    prompt_auto_install
    # 更新镜像源
    update_mirrorlist
    
    success "Setup completed successfully!"
}

# 捕获 Ctrl+C
trap 'echo -e "\n${RED}[!] Script interrupted by user.${RESET}"; exit 1' SIGINT

# 执行主函数
main "$@"

## ## ## ## ##