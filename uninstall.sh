#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

echo -e "${RED}==========================================================${PLAIN}"
echo -e "${RED}      Cloudflare Tunnel + Xray 一键卸载脚本               ${PLAIN}"
echo -e "${RED}      警告：这将停止服务并删除所有相关文件                ${PLAIN}"
echo -e "${RED}==========================================================${PLAIN}"

# 1. 确认提示
read -p "确认要执行卸载吗? [y/n] (默认: n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}已取消卸载。${PLAIN}"
    exit 0
fi

# 2. 停止进程
echo -e "${GREEN}[1/3] 正在停止后台服务...${PLAIN}"
# 使用 -f 模糊匹配，确保杀掉带参数运行的进程
pkill -f xray
pkill -f cloudflared

# 再次检查，防止残留
sleep 1
if pgrep -f xray > /dev/null; then killall -9 xray; fi
if pgrep -f cloudflared > /dev/null; then killall -9 cloudflared; fi

# 3. 删除文件
echo -e "${GREEN}[2/3] 正在清理文件...${PLAIN}"

# 删除核心程序目录
rm -rf xray

# 删除下载的 Cloudflare 程序
rm -f cloudflared-linux

# 删除生成的日志和配置文件
rm -f cloudflared.log
rm -f config.json
rm -f nohup.out

# 删除生成的节点链接文件
rm -f vmess_cf.txt
rm -f vmess_auto.txt

# 删除安装脚本本身 (可选，保留以便以后重新安装)
# rm -f install.sh

echo -e "${GREEN}[3/3] 卸载完成！${PLAIN}"
echo -e "所有组件已停止并删除，系统已恢复干净。"
