#!/bin/bash

# --- 0. 环境初始化与配置 ---
set -e  # 遇到错误立即退出

# 定义新旧版本号，方便未来再次升级
OLD_VER="2026.4.30"
NEW_VER="2026.5.7"

WORKDIR="$HOME/rech"
echo "========================================"
echo "  开始更新 Hermes Agent 环境"
echo "  从版本: $OLD_VER  =>  升级至: $NEW_VER"
echo "========================================"

# --- 1. 退出虚拟环境 (防错处理) ---
echo ">>> [1/5] 尝试退出当前虚拟环境..."
# 注意：在脚本中执行 deactivate 只对当前脚本进程生效
# 使用 || true 防止因为没有激活环境而导致脚本报错中断
if command -v deactivate &> /dev/null; then
    deactivate || true
    echo "已退出当前环境。"
else
    echo "当前无激活的虚拟环境，继续跳过。"
fi

# 确保进入工作目录
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# --- 2. 清理旧版本数据 ---
echo ""
echo ">>> [2/5] 清理旧版本数据 ($OLD_VER)..."
# 强制删除旧目录和旧压缩包 (这里直接删整个目录就包含 venv 了)
rm -rf "hermes-agent-${OLD_VER}/"
rm -rf "v${OLD_VER}.zip"
echo "✅ 旧版本清理完毕。"

# --- 3. 下载并解压新版本 ---
echo ""
echo ">>> [3/5] 获取新版本 ($NEW_VER)..."
wget -N "https://gh-proxy.org/https://github.com/NousResearch/hermes-agent/archive/refs/tags/v2026.5.7.zip"

echo ""
echo ">>> 解压新版本..."
unzip -o "v${NEW_VER}.zip"

# --- 4. 配置新版本的 Python 虚拟环境 ---
echo ""
echo ">>> [4/5] 部署新版本虚拟环境..."
cd "hermes-agent-${NEW_VER}/"

python3 -m venv venv
source venv/bin/activate

# 升级 pip 并安装依赖 
pip install --upgrade pip
pip install -e . -i https://mirrors.aliyun.com/pypi/simple/
pip install lark-oapi python-multipart --upgrade

# --- 5. 更新 Bash 自动激活路径 ---
echo ""
echo ">>> [5/5] 更新 ~/.bashrc 中的激活路径..."

NEW_VENV_PATH="$(pwd)/venv/bin/activate"
ACTIVATE_STR="if [ -f $NEW_VENV_PATH ]; then source $NEW_VENV_PATH; fi"

# 删除旧的 hermes-agent 激活路径，防止冲突
sed -i '/hermes-agent/d' ~/.bashrc

# 写入新的激活路径
echo "$ACTIVATE_STR" >> ~/.bashrc
echo "✅ .bashrc 配置已更新指向: $NEW_VER"

echo ""
echo "========================================"
echo "  ✅ 卢梭博客园"
echo "  由于你在旧环境中，请务必执行以下命令刷新："
echo "  source ~/.bashrc"
echo "========================================"