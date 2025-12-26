#!/bin/bash
set -euo pipefail
#
# 名称:     Sycamore Arch Setup
#
# 用法:     bash <(curl -fsSL arch.sycamore.icu)
#
# ==============================================================================

# ==============================================================================
# 全局变量
# ==============================================================================

VERSION="0.1.0"
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
        warn "Running in DEV MODE - some system checks may be skipped on failure"
    fi
    
    # 1. 检查 Root 权限
    info "Checking root privileges..."
    if [[ $EUID -ne 0 ]]; then
        error "This script requires root privileges. Please run with ${BOLD_WHITE}sudo${RESET} or switch to ${BOLD_WHITE}root${RESET} user."
        exit 1
    fi
    success "Running as root"
    
    # 2. 检查是否为 Arch Linux
    info "Checking Linux distribution..."
    if [[ ! -f /etc/arch-release ]]; then
        error "Non-Arch Linux system detected. Installation stopped."
        exit 1
    else
        success "Arch Linux detected"
    fi

    # 3. 检查 Root 文件系统是否为 Btrfs
    info "Checking Root filesystem..."
    local root_fstype=$(findmnt -n -o FSTYPE /)
    
    if [[ "${root_fstype}" != "btrfs" ]]; then
        error "Root is not Btrfs (detected: ${root_fstype})."
        error "This installation requires Btrfs filesystem for snapshot protection."
        exit 1
    else
        success "Root is Btrfs"
    fi

    # 4. 检查 /home 文件系统（如果是独立挂载点）
    info "Checking Home filesystem..."
    if findmnt /home &> /dev/null; then
        local home_fstype=$(findmnt -n -o FSTYPE /home 2>/dev/null)
        
        if [[ "${home_fstype}" != "btrfs" ]]; then
            error "Home is not Btrfs (detected: ${home_fstype})."
            error "All filesystems must be Btrfs for snapshot protection."
            exit 1
        else
            success "Home is Btrfs"
        fi
    else
        info "/home is not a separate mount point (using root filesystem)"
    fi

    # 5. 检查磁盘剩余空间 (>10GB)
    info "Checking available disk space..."
    local available_kb=$(df -k / | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [[ $available_kb -lt 10485760 ]]; then
        if [[ "${DEV_MODE}" == "1" ]]; then
            warn "Insufficient disk space (${available_gb}GB available). ${DIM}(Skipped in dev mode)${RESET}"
        else
            error "Insufficient disk space. At least 10GB of available space is required."
            error "Current available space: ${available_gb}GB"
            exit 1
        fi
    else
        success "Sufficient disk space available (${available_gb}GB)"
    fi
    
    success "All system checks passed."
    echo ""
}


# 打印章节标题
# 用法: print_section_title "Section Title"
print_section_title() {
    local title="$1"
    echo -e "${HEADER}[SECTION]${RESET} ${BOLD_WHITE}${title}${RESET}"
}

# 执行命令并限制日志输出
# 用法: run_command "description" command [args...]
# 示例: run_command "Updating system packages" pacman -Syu --noconfirm
run_command() {
    local description="${1:-Executing command}"
    shift
    local cmd=("$@")
    local max_lines=5
    local line_count=0
    local buffer=()

    info "${description}..."
    info "Command: ${cmd[*]}"

    # 执行命令并捕获输出
    {
        "${cmd[@]}" 2>&1 | while IFS= read -r line; do
            # 更新缓冲区（保持最后 max_lines 行，截断超过80字符的行）
            buffer+=("${line:0:80}")
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
    fi

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
            run_command "Installing reflector" pacman -Sy --noconfirm reflector || {
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
        run_command "Updating mirror list" ${reflector_cmd} || {
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
        run_command "Updating system packages" pacman -Syu --noconfirm || {
            error "Failed to update system"
            return 1
        }
        
        success "System update completed"
        echo ""
    fi
}

# ==============================================================================
# Btrfs 快照管理系统 (Snapper)
# ==============================================================================

# 初始化 Btrfs 快照系统并创建初始安全快照
init_btrfs_snapshots() {
    print_section_title "System Snapshot Initialization"
    
    # 安装 Snapper 和 snap-pac
    info "Installing Snapper and snap-pac..."
    run_command "Installing snapshot tools" pacman -Syu --noconfirm --needed snapper snap-pac || {
        error "Failed to install Snapper"
        return 1
    }
    
    # 配置 Root 快照
    info "Configuring Snapper for Root..."
    
    # 检查配置是否已存在
    if snapper list-configs 2>/dev/null | grep -q "^root "; then
        info "Config 'root' already exists"
    else
        # 清理现有的 .snapshots 目录
        if [[ -d "/.snapshots" ]]; then
            info "Cleaning up existing .snapshots directory..."
            umount /.snapshots 2>/dev/null || true
            rm -rf /.snapshots
        fi
        
        # 创建配置
        if run_command "Creating Snapper configuration" snapper -c root create-config /; then
            success "Config 'root' created"
            
            # 应用保留策略
            info "Applying retention policy..."
            # ALLOW_GROUPS="wheel"           - 允许 wheel 组用户访问快照
            # TIMELINE_CREATE="yes"          - 启用时间线快照（自动定期创建）
            # TIMELINE_CLEANUP="yes"         - 启用时间线清理（自动删除旧快照）
            # NUMBER_LIMIT="10"              - 最多保留 10 个普通快照
            # NUMBER_LIMIT_IMPORTANT="5"     - 最多保留 5 个重要快照
            # TIMELINE_LIMIT_HOURLY="5"      - 每小时快照保留 5 个
            # TIMELINE_LIMIT_DAILY="7"       - 每日快照保留 7 个
            # TIMELINE_LIMIT_WEEKLY="0"      - 每周快照保留 0 个（不保留）
            # TIMELINE_LIMIT_MONTHLY="0"     - 每月快照保留 0 个（不保留）
            # TIMELINE_LIMIT_YEARLY="0"      - 每年快照保留 0 个（不保留）
            snapper -c root set-config \
                ALLOW_GROUPS="wheel" \
                TIMELINE_CREATE="yes" \
                TIMELINE_CLEANUP="yes" \
                NUMBER_LIMIT="10" \
                NUMBER_LIMIT_IMPORTANT="5" \
                TIMELINE_LIMIT_HOURLY="5" \
                TIMELINE_LIMIT_DAILY="7" \
                TIMELINE_LIMIT_WEEKLY="0" \
                TIMELINE_LIMIT_MONTHLY="0" \
                TIMELINE_LIMIT_YEARLY="0"
            
            success "Retention policy applied"
        else
            error "Failed to create Snapper configuration"
            return 1
        fi
    fi
    
    # 配置 /home 快照（如果是独立的 Btrfs 挂载点）
    if findmnt /home &> /dev/null; then
        info "Configuring Snapper for Home..."
        
        if ! snapper list-configs 2>/dev/null | grep -q "^home "; then
            # 清理 /home/.snapshots
            if [[ -d "/home/.snapshots" ]]; then
                umount /home/.snapshots 2>/dev/null || true
                rm -rf /home/.snapshots
            fi
            
            if run_command "Creating Home configuration" snapper -c home create-config /home; then
                success "Config 'home' created"
                
                # 应用与 root 相同的保留策略
                # ALLOW_GROUPS="wheel"           - 允许 wheel 组用户访问快照
                # TIMELINE_CREATE="yes"          - 启用时间线快照
                # TIMELINE_CLEANUP="yes"         - 启用时间线清理
                # NUMBER_LIMIT="10"              - 最多保留 10 个普通快照
                # NUMBER_LIMIT_IMPORTANT="5"     - 最多保留 5 个重要快照
                # TIMELINE_LIMIT_HOURLY="5"      - 每小时快照保留 5 个
                # TIMELINE_LIMIT_DAILY="7"       - 每日快照保留 7 个
                # TIMELINE_LIMIT_WEEKLY="0"      - 不保留每周快照
                # TIMELINE_LIMIT_MONTHLY="0"     - 不保留每月快照
                # TIMELINE_LIMIT_YEARLY="0"      - 不保留每年快照
                snapper -c home set-config \
                    ALLOW_GROUPS="wheel" \
                    TIMELINE_CREATE="yes" \
                    TIMELINE_CLEANUP="yes" \
                    NUMBER_LIMIT="10" \
                    NUMBER_LIMIT_IMPORTANT="5" \
                    TIMELINE_LIMIT_HOURLY="5" \
                    TIMELINE_LIMIT_DAILY="7" \
                    TIMELINE_LIMIT_WEEKLY="0" \
                    TIMELINE_LIMIT_MONTHLY="0" \
                    TIMELINE_LIMIT_YEARLY="0"
            fi
        else
            info "Config 'home' already exists"
        fi
    else
        info "/home is not a separate mount point. Using root filesystem."
    fi
    
    success "System snapshot configuration completed"
    echo ""
    
    # 创建初始安全快照
    print_section_title "Creating Initial Snapshots"
    
    # 检查是否已存在初始快照（避免重复创建）
    local initial_snapshot_exists=false
    
    # 创建 Root 快照
    if snapper list-configs 2>/dev/null | grep -q "^root "; then
        # 检查是否已存在描述为 "Before Sycamore Arch Setup" 的快照
        if snapper -c root list 2>/dev/null | grep -q "Before Sycamore Arch Setup"; then
            info "Initial Root snapshot already exists, skipping creation"
            initial_snapshot_exists=true
        else
            info "Creating Root snapshot..."
            local root_snapshot
            root_snapshot=$(snapper -c root create --description "Before Sycamore Arch Setup" --cleanup-algorithm number --print-number 2>&1)
            
            if [[ $? -eq 0 ]]; then
                success "Root snapshot created: #${root_snapshot}"
            else
                error "Failed to create Root snapshot"
                warn "Cannot proceed without a safety snapshot. Aborting."
                return 1
            fi
        fi
    fi
    
    # 创建 Home 快照（如果配置存在）
    if snapper list-configs 2>/dev/null | grep -q "^home "; then
        # 检查是否已存在描述为 "Before Sycamore Arch Setup" 的快照
        if snapper -c home list 2>/dev/null | grep -q "Before Sycamore Arch Setup"; then
            info "Initial Home snapshot already exists, skipping creation"
        else
            info "Creating Home snapshot..."
            local home_snapshot=$(snapper -c home create --description "Before Sycamore Arch Setup" --cleanup-algorithm number --print-number 2>&1)
            
            if [[ $? -eq 0 ]]; then
                success "Home snapshot created: #${home_snapshot}"
            else
                error "Failed to create Home snapshot"
                return 1
            fi
        fi
    fi
    
    # 显示 Root 快照（使用 ISO 8601 时间格式）
    if snapper list-configs 2>/dev/null | grep -q "^root "; then
        info "Root snapshots:"
        snapper --iso -c root list 2>/dev/null | tail -n +3 | while IFS= read -r line; do
            echo -e "${DIM}  │ ${line}${RESET}"
        done
    fi
    
    # 显示 Home 快照（如果存在，使用 ISO 8601 时间格式）
    if snapper list-configs 2>/dev/null | grep -q "^home "; then
        info "Home snapshots:"
        snapper --iso -c home list 2>/dev/null | tail -n +3 | while IFS= read -r line; do
            echo -e "${DIM}  │ ${line}${RESET}"
        done
    fi

    if [[ "${initial_snapshot_exists}" == "true" ]]; then
        success "Using existing initial snapshots"
    else
        success "Initial snapshots created successfully"
    fi
    echo ""
}

# 在包安装前创建快照
create_pre_snapshot() {
    local description="$1"
    
    debug "Creating pre-snapshot: ${description}"
    
    local snapshot_number=$(snapper -c root create --type pre --cleanup-algorithm number --description "${description}" --print-number 2>&1)
    
    if [[ $? -eq 0 ]]; then
        echo "${snapshot_number}"
        return 0
    else
        error "Failed to create pre-snapshot: ${snapshot_number}"
        return 1
    fi
}

# 在包安装后创建快照
create_post_snapshot() {
    local pre_number="$1"
    local description="$2"
    
    debug "Creating post-snapshot paired with #${pre_number}: ${description}"
    
    local snapshot_number=$(snapper -c root create --type post --cleanup-algorithm number --pre-number "${pre_number}" --description "${description}" --print-number 2>&1)
    
    if [[ $? -eq 0 ]]; then
        echo "${snapshot_number}"
        return 0
    else
        error "Failed to create post-snapshot: ${snapshot_number}"
        return 1
    fi
}

# 恢复到指定快照
rollback_to_snapshot() {
    local snapshot_number="$1"
    
    warn "Rolling back to snapshot #${snapshot_number}..."
    
    # 显示快照信息
    info "Snapshot information:"
    snapper -c root list | grep "^${snapshot_number} " | while IFS= read -r line; do
        echo -e "${DIM}  │ ${line}${RESET}"
    done
    
    # 执行回滚
    run_command "Rolling back changes" snapper -c root undochange ${snapshot_number}..0 || {
        error "Failed to rollback to snapshot #${snapshot_number}"
        return 1
    }
    
    success "Successfully rolled back to snapshot #${snapshot_number}"
    warn "Some changes may require a reboot to take full effect"
    echo ""
}

# 检查步骤是否已完成（基于快照检查）
# 用法: is_step_completed "description"
is_step_completed() {
    local description="$1"
    
    # 检查是否存在对应的 post-snapshot
    if snapper -c root list 2>/dev/null | grep -q "After ${description}"; then
        return 0  # 已完成
    else
        return 1  # 未完成
    fi
}

# 检查是否存在未配对的 pre-snapshot（安装中断检测）
# 用法: check_interrupted_snapshot "description"
# 返回: 如果存在孤立的 pre-snapshot，输出其编号；否则返回空
check_interrupted_snapshot() {
    local description="$1"
    
    # 查找所有 pre-snapshot
    while IFS= read -r line; do
        local snap_num=$(echo "${line}" | awk '{print $1}')
        local snap_type=$(echo "${line}" | awk '{print $2}')
        local snap_desc=$(echo "${line}" | awk -F'|' '{print $NF}' | xargs)
        
        # 检查是否是目标 pre-snapshot
        if [[ "${snap_type}" == "pre" ]] && [[ "${snap_desc}" == "Before ${description}" ]]; then
            # 检查是否有配对的 post-snapshot
            local has_post=$(snapper -c root list 2>/dev/null | grep "post" | grep -c "${snap_num}")
            
            if [[ ${has_post} -eq 0 ]]; then
                # 找到孤立的 pre-snapshot
                echo "${snap_num}"
                return 0
            fi
        fi
    done < <(snapper -c root list 2>/dev/null | tail -n +3)
    
    return 1
}

# 运行带快照保护的包安装步骤
# 用法: run_step_with_snapshot "function_name" "description"
run_step_with_snapshot() {
    local step_func="$1"
    local description="$2"
    
    # 检查是否已完成（基于快照）
    if is_step_completed "${description}"; then
        if [[ "${AUTO_INSTALL}" == "true" ]]; then
            info "Skipping '${description}' ${DIM}(already completed)${RESET}"
            return 0
        else
            # 交互模式：询问用户是否跳过
            while true; do
                read -p "$(echo -e "${PROMPT}Step '${description}' already completed. Skip? [Y/n]:${RESET} ")" choice
                choice=${choice:-y}
                case $choice in
                    y|Y|yes|YES|"")
                        info "Skipping '${description}'"
                        return 0
                        ;;
                    n|N|no|NO)
                        warn "Re-running '${description}'..."
                        break
                        ;;
                    *)
                        error "Invalid option. Please enter Y or N"
                        ;;
                esac
            done
        fi
    fi
    
    # 检查是否存在未配对的 pre-snapshot（安装中断检测）
    local interrupted_snapshot=$(check_interrupted_snapshot "${description}")
    
    if [[ -n "${interrupted_snapshot}" ]]; then
        warn "Detected interrupted installation for '${description}'"
        warn "Found orphaned pre-snapshot #${interrupted_snapshot}"
        
        # 显示快照信息
        info "Snapshot details:"
        snapper -c root list 2>/dev/null | grep "^${interrupted_snapshot} " | while IFS= read -r line; do
            echo -e "${DIM}  │ ${line}${RESET}"
        done
        echo ""
        
        local do_rollback=false
        
        if [[ "${AUTO_INSTALL}" == "true" ]]; then
            warn "Auto-install mode: automatically rolling back to pre-snapshot #${interrupted_snapshot}"
            do_rollback=true
        else
            # 交互模式：询问用户如何处理
            while true; do
                echo -e "${PROMPT}How to handle the interrupted installation?${RESET}"
                echo -e "  ${BOLD_WHITE}1)${RESET} Rollback to snapshot #${interrupted_snapshot} (recommended)"
                echo -e "  ${BOLD_WHITE}2)${RESET} Delete old snapshot and continue with new installation"
                read -p "$(echo -e "${PROMPT}Choose option [1/2]:${RESET} ")" choice
                choice=${choice:-1}
                case $choice in
                    1)
                        do_rollback=true
                        break
                        ;;
                    2)
                        info "Deleting orphaned snapshot #${interrupted_snapshot}..."
                        snapper -c root delete "${interrupted_snapshot}" 2>/dev/null
                        if [[ $? -eq 0 ]]; then
                            success "Snapshot #${interrupted_snapshot} deleted"
                        else
                            warn "Failed to delete snapshot #${interrupted_snapshot}"
                        fi
                        break
                        ;;
                    *)
                        error "Invalid option. Please enter 1 or 2"
                        ;;
                esac
            done
        fi
        
        if [[ "${do_rollback}" == "true" ]]; then
            rollback_to_snapshot "${interrupted_snapshot}"
            # 回滚后删除该快照
            info "Cleaning up snapshot #${interrupted_snapshot}..."
            snapper -c root delete "${interrupted_snapshot}" 2>/dev/null
            success "System restored to pre-installation state"
            return 0
        fi
    fi
    
    # 创建预快照
    local pre_snapshot=$(create_pre_snapshot "Before ${description}")
    
    if [[ $? -ne 0 ]] || [[ -z "${pre_snapshot}" ]]; then
        warn "Failed to create pre-snapshot, continuing without snapshot protection..."
        pre_snapshot=""
    else
        debug "Pre-snapshot #${pre_snapshot} created for ${step_func}"
    fi
    
    # 执行步骤函数
    if "${step_func}"; then
        # 成功：创建后快照
        if [[ -n "${pre_snapshot}" ]]; then
            local post_snapshot=$(create_post_snapshot "${pre_snapshot}" "After ${description}")
            if [[ $? -eq 0 ]]; then
                debug "Post-snapshot #${post_snapshot} created for ${step_func}"
            fi
        fi
        
        return 0
    else
        # 失败：询问是否回滚
        error "Step '${description}' failed"
        
        if [[ -n "${pre_snapshot}" ]]; then
            local do_rollback=false
            
            if [[ "${AUTO_INSTALL}" == "true" ]]; then
                warn "Auto-install mode: automatically rolling back to pre-snapshot #${pre_snapshot}"
                do_rollback=true
            else
                while true; do
                    read -p "$(echo -e "${PROMPT}Rollback to snapshot #${pre_snapshot}? [Y/n]:${RESET} ")" choice
                    choice=${choice:-y}
                    case $choice in
                        y|Y|yes|YES|"")
                            do_rollback=true
                            break
                            ;;
                        n|N|no|NO)
                            info "Skipping rollback. You can manually rollback later with: snapper -c root undochange ${pre_snapshot}..0"
                            break
                            ;;
                        *)
                            error "Invalid option. Please enter Y or N"
                            ;;
                    esac
                done
            fi
            
            if [[ "${do_rollback}" == "true" ]]; then
                rollback_to_snapshot "${pre_snapshot}"
            fi
        fi
        
        return 1
    fi
}

# ==============================================================================
# 基础系统配置
# ==============================================================================

# 基础系统配置函数
setup_base_system() {
    print_section_title "Base System Configuration"
    
    # ------------------------------------------------------------------------------
    # 1. 设置全局默认编辑器
    # ------------------------------------------------------------------------------
    info "Step 1/5: Configuring global default editor"
    
    local target_editor="vim"
    
    if command -v nvim &> /dev/null; then
        target_editor="nvim"
        debug "Neovim detected"
    elif command -v nano &> /dev/null; then
        target_editor="nano"
        debug "Nano detected"
    else
        info "Neovim or Nano not found. Installing Vim..."
        if ! command -v vim &> /dev/null; then
            run_command "Installing gvim" pacman -Syu --noconfirm gvim || return 1
        fi
    fi
    
    info "Setting EDITOR=${target_editor} in /etc/environment..."
    
    if grep -q "^EDITOR=" /etc/environment 2>/dev/null; then
        sed -i "s/^EDITOR=.*/EDITOR=${target_editor}/" /etc/environment
    else
        echo "EDITOR=${target_editor}" >> /etc/environment
    fi
    success "Global EDITOR set to: ${target_editor}"
    echo ""
    
    # ------------------------------------------------------------------------------
    # 2. 启用 32-bit (multilib) 仓库
    # ------------------------------------------------------------------------------
    info "Step 2/5: Enabling multilib repository"
    
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        success "[multilib] is already enabled"
    else
        info "Uncommenting [multilib]..."
        sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
        
        info "Refreshing package database..."
        run_command "Refreshing database" pacman -Sy || return 1
        success "[multilib] enabled"
    fi
    echo ""
    
    # ------------------------------------------------------------------------------
    # 3. 安装基础字体
    # ------------------------------------------------------------------------------
    info "Step 3/5: Installing base fonts"
    
    run_command "Installing fonts" pacman -Syu --noconfirm --needed adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts noto-fonts-cjk noto-fonts noto-fonts-emoji || return 1
    success "Base fonts installed"
    echo ""
    
    # ------------------------------------------------------------------------------
    # 4. 配置 archlinuxcn 仓库
    # ------------------------------------------------------------------------------
    info "Step 4/5: Configuring ArchLinuxCN repository"
    
    if grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
        success "archlinuxcn repository already exists"
    else
        info "Adding archlinuxcn mirrors to pacman.conf..."
        cat <<EOT >> /etc/pacman.conf

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
Server = https://mirrors.hit.edu.cn/archlinuxcn/\$arch
Server = https://repo.huaweicloud.com/archlinuxcn/\$arch
EOT
        success "Mirrors added"
    fi
    
    info "Installing archlinuxcn-keyring..."
    run_command "Installing keyring" pacman -Sy --noconfirm archlinuxcn-keyring || return 1
    success "ArchLinuxCN configured"
    echo ""
    
    # ------------------------------------------------------------------------------
    # 5. 安装 AUR 助手
    # ------------------------------------------------------------------------------
    info "Step 5/5: Installing AUR helpers"
    
    run_command "Installing yay and paru" pacman -Syu --noconfirm --needed base-devel yay paru || return 1
    success "AUR helpers installed"
    echo ""
    
    success "Base system configuration completed"
    echo ""
    return 0
}


# ==============================================================================
# 主逻辑
# ==============================================================================

main() {
    show_banner

    # 系统信息
    system_information

    # 必要检查
    check_system_requirements

    # 安装模式选择
    prompt_auto_install
    
    # 更新源
    update_mirrorlist
    
    # 更新系统
    update_system
    
    # 初始化 Btrfs 快照系统并创建初始快照
    init_btrfs_snapshots

    # 基础系统配置（使用快照保护）
    run_step_with_snapshot "setup_base_system" "Base System Configuration"
}

# 捕获 Ctrl+C
trap 'echo -e "\n${RED}[!] Script interrupted by user.${RESET}"; exit 1' SIGINT

# 执行主函数
main "$@"

## ## ## ##