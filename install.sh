#!/bin/bash

set -e  # 遇到错误立即退出

echo "========================================"
echo "  开始安装 Hermes Agent 环境"
echo "========================================"

# 1. 下载压缩包
echo ""
echo ">>> [1/6] 下载 hermes-agent..."
wget https://gh-proxy.org/https://github.com/NousResearch/hermes-agent/archive/refs/tags/v2026.4.30.zip

# 2. 安装 unzip
echo ""
echo ">>> [2/6] 安装 unzip..."
apt install -y unzip

# 3. 解压
echo ""
echo ">>> [3/6] 解压文件..."
unzip v2026.4.30.zip

# 4. 安装 Node.js 23
echo ""
echo ">>> [4/6] 配置并安装 Node.js 23..."
curl -fsSL https://deb.nodesource.com/setup_23.x | bash -
apt install -y nodejs

# 5. 安装编译工具
echo ""
echo ">>> [5/6] 安装编译工具 (build-essential / make / g++)..."
apt update && apt install -y build-essential make g++

# 6. 安装 hermes-web-ui
echo ""
echo ">>> [6/6] 安装 hermes-web-ui (使用国内镜像)..."
npm install -g hermes-web-ui --registry=https://registry.npmmirror.com

echo ""
echo "========================================"
echo "  ✅ 全部安装完成！"
echo "========================================"
