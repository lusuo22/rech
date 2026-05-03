#!/bin/bash

# --- 0. 环境初始化 ---
set -e

# 针对 WSL root 登录优化路径识别
if [ "$USER" = "root" ]; then
    REAL_USER="root"
    REAL_HOME="/root"
else
    REAL_USER=$(logname 2>/dev/null || echo $USER)
    REAL_HOME=$(eval echo "~$REAL_USER")
fi

echo "========================================"
echo "  开始安装 Hermes Agent 环境 (用户: $REAL_USER)"
echo "========================================"

# 使用绝对路径，避免变量为空导致的 cd 报错
WORKDIR="$REAL_HOME/rech"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# --- 1. 基础工具准备 ---
echo ">>> [1/9] 更新系统并安装基础工具..."
apt update && apt install -y wget unzip

# --- 2. 下载与解压 ---
echo ""
echo ">>> [2/9] 下载 hermes-agent..."
wget -N https://gh-proxy.org/https://github.com/NousResearch/hermes-agent/archive/refs/tags/v2026.4.30.zip

echo ""
echo ">>> [3/9] 解压文件..."
unzip -o v2026.4.30.zip

# --- 3. Node.js 环境 ---
echo ""
echo ">>> [4/9] 安装 Node.js 23..."
curl -fsSL https://deb.nodesource.com/setup_23.x | bash -
apt install -y nodejs

# --- 4. 编译工具与 Web UI ---
echo ""
echo ">>> [5/9] 安装编译工具..."
apt install -y build-essential make g++
npm install -g hermes-web-ui --registry=https://registry.npmmirror.com

# --- 5. Python 环境 ---
echo ""
echo ">>> [6/9] 检测 Python 并安装 venv..."
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
apt install "python${PY_VERSION}-venv" -y

# --- 6. 虚拟环境配置 ---
echo ""
echo ">>> [7/9] 配置项目依赖..."
TARGET_DIR="$WORKDIR/hermes-agent-2026.4.30"
if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR"
else
    echo "❌ 错误: 找不到目录 $TARGET_DIR"
    exit 1
fi

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -e . -i https://mirrors.aliyun.com/pypi/simple/
pip install lark-oapi python-multipart --upgrade

# --- 7. 自动激活配置 ---
VENV_PATH="$TARGET_DIR/venv/bin/activate"
ACTIVATE_STR="if [ -f $VENV_PATH ]; then source $VENV_PATH; fi"

# 统一写入 .bashrc
[ -f "$REAL_HOME/.bashrc" ] && ! grep -q "$VENV_PATH" "$REAL_HOME/.bashrc" && echo "$ACTIVATE_STR" >> "$REAL_HOME/.bashrc"
[ -f "/root/.bashrc" ] && ! grep -q "$VENV_PATH" "/root/.bashrc" && echo "$ACTIVATE_STR" >> "/root/.bashrc"

# 如果不是 root 用户，修正权限
if [ "$REAL_USER" != "root" ]; then
    chown -R "$REAL_USER":"$REAL_USER" "$WORKDIR"
fi

echo "========================================"
echo "  ✅ 全部部署完成！"
echo "  提示：请执行 'source ~/.bashrc' 生效"
echo "========================================"