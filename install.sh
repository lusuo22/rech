#!/bin/bash

# --- 0. 环境初始化 ---
set -e  # 遇到错误立即退出

# 识别真实的执行用户，增加保底逻辑防止 logname 报错
REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER || echo $USER || echo "root")
REAL_HOME=$(eval echo "~$REAL_USER")

echo "========================================"
echo "  开始安装 Hermes Agent 环境 (执行用户: $REAL_USER)"
echo "========================================"

# 锁定工作目录，确保下载位置固定[cite: 3]
WORKDIR="$REAL_HOME/rech"
mkdir -p "$WORKDIR" && cd "$WORKDIR"[cite: 3]

# --- 1. 基础工具准备 ---
echo ">>> [1/9] 更新系统并安装基础工具..."
# 移除 curl 以避免正在运行的脚本产生冲突，只安装 wget 和 unzip[cite: 3]
apt update && apt install -y wget unzip[cite: 3]

# --- 2. 下载与解压 ---
echo ""
echo ">>> [2/9] 下载 hermes-agent..."
wget -N https://gh-proxy.org/https://github.com/NousResearch/hermes-agent/archive/refs/tags/v2026.4.30.zip[cite: 3]

echo ""
echo ">>> [3/9] 解压文件..."
unzip -o v2026.4.30.zip[cite: 3]

# --- 3. Node.js 环境 ---
echo ""
echo ">>> [4/9] 配置并安装 Node.js 23..."
# 使用 curl 静默下载并执行官方安装脚本[cite: 3]
curl -fsSL https://deb.nodesource.com/setup_23.x | bash -[cite: 3]
apt install -y nodejs[cite: 3]

# --- 4. 编译工具与 Web UI ---
echo ""
echo ">>> [5/9] 安装编译工具 (build-essential / make / g++)..."
apt install -y build-essential make g++[cite: 3]

echo ""
echo ">>> [6/9] 安装 hermes-web-ui (使用国内镜像)..."
npm install -g hermes-web-ui --registry=https://registry.npmmirror.com[cite: 3]

# --- 5. Python 环境 ---
echo ""
echo ">>> [7/9] 动态检测 Python 版本并安装 venv..."
# 获取当前 python3 的主版本号[cite: 3]
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')[cite: 3]
echo "检测到当前 Python 版本为: $PY_VERSION"
apt install "python${PY_VERSION}-venv" -y[cite: 3]

# --- 6. 虚拟环境配置 ---
echo ""
echo ">>> [8/9] 配置项目依赖..."
TARGET_DIR="$WORKDIR/hermes-agent-2026.4.30"
if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR"[cite: 3]
else
    echo "❌ 错误: 找不到目录 $TARGET_DIR"
    exit 1
fi

python3 -m venv venv[cite: 3]
source venv/bin/activate[cite: 3]

# 使用镜像加速安装依赖[cite: 3]
pip install --upgrade pip[cite: 3]
pip install -e . -i https://mirrors.aliyun.com/pypi/simple/[cite: 3]
pip install lark-oapi python-multipart --upgrade[cite: 3]

# --- 7. 自动激活配置 ---
echo ""
echo ">>> [9/9] 设置 Bash 自动激活虚拟环境..."

VENV_PATH="$TARGET_DIR/venv/bin/activate"[cite: 3]
ACTIVATE_STR="if [ -f $VENV_PATH ]; then source $VENV_PATH; fi"

# 为普通用户配置 .bashrc[cite: 3]
if ! grep -q "$VENV_PATH" "$REAL_HOME/.bashrc"; then
    echo "$ACTIVATE_STR" >> "$REAL_HOME/.bashrc"
    echo "✅ 已将激活命令添加到 $REAL_HOME/.bashrc"[cite: 3]
fi

# 为 root 用户配置 (确保 sudo -i 时也激活)[cite: 3]
if [ "$EUID" -eq 0 ] || [ -d "/root" ]; then
    if ! grep -q "$VENV_PATH" /root/.bashrc; then
        echo "$ACTIVATE_STR" >> /root/.bashrc
        echo "✅ 已为 root 用户配置自动激活"[cite: 3]
    fi
fi

# 修正目录所有权，让普通用户可以正常使用[cite: 3]
chown -R "$REAL_USER":"$REAL_USER" "$WORKDIR"

echo ""
echo "========================================"
echo "  ✅ 全部部署完成！"
echo "  咸鱼大王：https://www.cnblogs.com/lusuo/p/19576399"[cite: 3]
echo "  提示：请执行 'source ~/.bashrc' 激活环境"
echo "========================================"