# Sycamore Arch Setup

一个用于 Arch Linux 系统的自动化配置脚本集合, 专注于快速部署 Niri 窗口管理器环境。

## 🎯 项目简介

`Sycamore Arch Setup` 是一个模块化的 Arch Linux 安装脚本, 旨在自动化完成从基础系统配置到桌面环境部署的全过程。项目支持断点续传, 并提供完善的错误恢复机制。

## ✨ 核心特性

- **📸 Btrfs 快照保护**: 集成 Snapper 和 snap-pac，自动在包安装前后创建快照
- **🔄 断点续传**: 支持安装过程中断后继续，不会重复已完成的步骤
- **⚡ 自动恢复**: 包安装失败时自动回滚到快照，保护系统稳定性
- **🎨 交互式 TUI**: 美观的终端界面，提供清晰的安装进度反馈
- **🌍 智能镜像源**: 自动检测地理位置并优化 Pacman 镜像源

## 📋 系统要求

- **操作系统**: Arch Linux
- **文件系统**: Btrfs (根分区必须使用 Btrfs)
- **磁盘空间**: 至少 10GB 可用空间
- **权限**: Root 权限

## 🚀 使用方式

### 一键安装

```shell
bash <(curl -fsSL arch.sycamore.icu)
```

### 开发模式

如果你在非 Arch 系统或非 Btrfs 文件系统上测试，可以使用开发模式（跳过系统检查）：

```shell
DEV_MODE=1 bash install.sh
```

## 📸 Btrfs 快照功能

### 自动快照

脚本会自动执行以下快照操作：

1. **初始快照**: 在开始安装前创建系统初始快照
2. **Pre/Post 快照**: 每次包安装前后自动创建配对快照（由 snap-pac 钩子管理）
3. **自动恢复**: 包安装失败时，自动回滚到安装前的快照

### 手动管理快照

安装完成后，你可以使用以下命令管理快照：

```bash
# 列出所有快照
snapper -c root list

# 查看两个快照之间的差异
snapper -c root status 1..2

# 回滚到指定快照
snapper -c root undochange 5..0

# 删除指定快照
snapper -c root delete 3
```

### 快照配置优化

脚本已自动优化 Snapper 配置：
- 每小时快照保留 5 个
- 每日快照保留 7 个
- 不保留周/月/年快照（避免占用过多空间）

## 🔧 安装流程

1. **系统检查**: 验证 Arch Linux、Btrfs 文件系统和磁盘空间
2. **进度恢复**: 检测是否有未完成的安装，支持继续或重新开始
3. **镜像源优化**: 自动选择最快的镜像服务器
4. **系统更新**: 更新现有软件包到最新版本
5. **Snapper 配置**: 安装并配置 Btrfs 快照工具
6. **初始快照**: 创建系统基准快照
7. **包安装保护**: 后续所有包安装都将受到快照保护

## 🛡️ 错误恢复机制

### 安装失败自动恢复

当包安装步骤失败时：

1. **自动模式**: 自动回滚到安装前的快照
2. **交互模式**: 询问用户是否回滚
   - 选择 Yes: 立即回滚到快照
   - 选择 No: 保留当前状态，用户可以手动处理

### 手动恢复

如果需要手动恢复到某个快照：

```bash
# 查看快照列表
snapper -c root list

# 回滚到快照 #5
snapper -c root undochange 5..0

# 某些变更可能需要重启生效
sudo reboot
```

## 📝 进度记录

安装进度保存在 `/tmp/sycamore-setup/progress`，包含：
- 已完成的安装步骤
- 创建的快照信息

如果安装中断，重新运行脚本时会自动检测并询问：
- **Continue**: 从上次中断的地方继续
- **Reset**: 清除进度重新开始
- **Quit**: 退出安装

## 🎯 最佳实践

1. **定期清理快照**: 避免快照占用过多磁盘空间
   ```bash
   snapper -c root list
   snapper -c root delete <old_snapshot_number>
   ```

2. **重要操作前手动快照**: 在进行系统级更改前创建快照
   ```bash
   snapper -c root create --description "Before major changes"
   ```

3. **监控磁盘空间**: Btrfs 快照会占用空间，定期检查
   ```bash
   df -h /
   btrfs filesystem usage /
   ```

## 🐛 故障排查

### 快照创建失败

如果 Snapper 无法创建快照：
- 检查 Btrfs 文件系统是否正常: `btrfs filesystem show /`
- 检查磁盘空间: `df -h /`
- 查看 Snapper 日志: `journalctl -u snapper`

### 回滚失败

如果回滚操作失败：
- 确认快照存在: `snapper -c root list`
- 手动检查快照内容: `ls /.snapshots/<number>/snapshot/`
- 使用 Btrfs 原生命令进行恢复

## 📚 相关资源

- [Snapper Wiki](https://wiki.archlinux.org/title/Snapper)
- [Btrfs Wiki](https://wiki.archlinux.org/title/Btrfs)
- [snap-pac](https://github.com/wesbarnett/snap-pac)

## 📄 许可证

本项目采用 MIT 许可证。
