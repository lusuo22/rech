#!/bin/bash

# --- 0. 环境初始化 ---
set -e  # 遇到错误立即退出

# 强制锁定在当前 Linux 用户的家目录下，不再依赖复杂的检测
# 这样即使在 root 下运行，也会精准进入 /root/rech
WORKDIR="$HOME/rech"

echo "========================================"
echo "  开始安装 Hermes Agent 环境"
echo "  工作目录: $WORKDIR"
echo "========================================"

# 确保工作目录存在并进入
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# --- 1. 基础工具准备 ---
echo ">>> [1/9] 更新系统并安装基础工具..."
# 仅安装必要的工具，跳过 curl
apt update && apt install -y wget unzip

# --- 2. 下载与解压 ---
echo ""
echo ">>> [2/9] 下载并解压 hermes-agent..."
wget -N https://gh-proxy.org/https://github.com/NousResearch/hermes-agent/archive/refs/tags/v2026.4.30.zip
unzip -o v2026.4.30.zip

# --- 3. Node.js 与 编译工具 ---
echo ""
echo ">>> [3/9] 安装 Node.js 23..."
curl -fsSL https://deb.nodesource.com/setup_23.x | bash -
apt install -y nodejs

echo ""
echo ">>> [4/9] 安装编译工具与 Web UI..."
apt install -y build-essential make g++
npm install -g hermes-web-ui --registry=https://registry.npmmirror.com

# --- 4. Python 环境 ---
echo ""
echo ">>> [5/9] 配置 Python 虚拟环境..."
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
apt install "python${PY_VERSION}-venv" -y

# 进入解压后的项目目录
cd hermes-agent-2026.4.30/

python3 -m venv venv
source venv/bin/activate

# 使用镜像加速安装依赖
pip install --upgrade pip
pip install -e . -i https://mirrors.aliyun.com/pypi/simple/
pip install lark-oapi python-multipart --upgrade

# --- 5. 自动激活配置 ---
VENV_PATH="$(pwd)/venv/bin/activate"
ACTIVATE_STR="if [ -f $VENV_PATH ]; then source $VENV_PATH; fi"

# 写入当前用户的 .bashrc
if ! grep -q "$VENV_PATH" ~/.bashrc; then
    echo "$ACTIVATE_STR" >> ~/.bashrc
    echo "✅ 已将激活命令添加到 ~/.bashrc"
fi

echo "========================================"
echo "  ✅ 部署完成！"
echo "  请执行: source ~/.bashrc"
echo "========================================"