#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

echo -e "${GREEN}==========================================================${PLAIN}"
echo -e "${GREEN}      Cloudflare Tunnel + Xray 一键部署脚本 (修复版)      ${PLAIN}"
echo -e "${GREEN}      适用：NAT 机器、动态 IP、无公网 IP 环境             ${PLAIN}"
echo -e "${GREEN}      功能：自动配置 Argo 隧道，生成标准 VMess 链接       ${PLAIN}"
echo -e "${GREEN}==========================================================${PLAIN}"

# 1. 检查并安装依赖
echo -e "${YELLOW}[1/6] 检查并安装必要组件...${PLAIN}"
if [[ -f /etc/redhat-release ]]; then
    yum install unzip wget curl jq -y > /dev/null 2>&1
else
    apt-get update > /dev/null 2>&1
    apt-get install unzip wget curl jq -y > /dev/null 2>&1
fi

# 2. 架构检测与程序下载
echo -e "${YELLOW}[2/6] 检测系统架构并下载核心...${PLAIN}"
ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
    XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
    CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
elif [[ $ARCH == "aarch64" ]]; then
    XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip"
    CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
else
    echo -e "${RED}不支持的架构: $ARCH${PLAIN}"
    exit 1
fi

# 清理旧文件
rm -rf xray cloudflared-linux cloudflared.log config.json
mkdir -p xray

# 下载 Xray
wget -q -O xray.zip $XRAY_URL
unzip -q xray.zip -d xray
rm -f xray.zip
chmod +x xray/xray

# 下载 Cloudflared
wget -q -O cloudflared-linux $CF_URL
chmod +x cloudflared-linux

# 3. 生成配置信息
echo -e "${YELLOW}[3/6] 生成随机端口与 UUID...${PLAIN}"
UUID=$(cat /proc/sys/kernel/random/uuid)
PATH_W="/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)"
LOCAL_PORT=$(shuf -i 10000-60000 -n 1)

# 创建 Xray 配置文件 (注意：这里强制监听 127.0.0.1，只允许隧道访问，安全！)
cat > xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $LOCAL_PORT,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [ { "id": "$UUID", "alterId": 0 } ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$PATH_W" }
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

# 4. 启动服务
echo -e "${YELLOW}[4/6] 启动后台服务...${PLAIN}"
pkill xray
pkill cloudflared

# 启动 Xray
nohup ./xray/xray run -c xray/config.json > /dev/null 2>&1 &

# 启动 Cloudflared (连接到上面的随机端口)
nohup ./cloudflared-linux tunnel --url http://127.0.0.1:$LOCAL_PORT --no-autoupdate > cloudflared.log 2>&1 &

# 5. 抓取域名 (关键步骤)
echo -e "${YELLOW}[5/6] 正在建立隧道，请稍候(约10秒)...${PLAIN}"
sleep 10
ARGO_DOMAIN=$(grep -oE "https://.*[a-z]+.trycloudflare.com" cloudflared.log | sed 's/https:\/\///' | head -n 1)

# 如果没抓到，循环等待一下
if [ -z "$ARGO_DOMAIN" ]; then
    sleep 10
    ARGO_DOMAIN=$(grep -oE "https://.*[a-z]+.trycloudflare.com" cloudflared.log | sed 's/https:\/\///' | head -n 1)
fi

if [ -z "$ARGO_DOMAIN" ]; then
    echo -e "${RED}错误：无法获取隧道域名，请检查网络或重新运行！${PLAIN}"
    echo -e "日志最后几行："
    tail -n 5 cloudflared.log
    exit 1
fi

# 6. 生成标准 VMess 链接
# 链接1：优选IP模式 (Address: speed.cloudflare.com, Host: 隧道域名)
VMESS_JSON_CF='{
  "v": "2",
  "ps": "Argo_优选IP_'$(hostname)'",
  "add": "speed.cloudflare.com",
  "port": "443",
  "id": "'$UUID'",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "'$ARGO_DOMAIN'",
  "path": "'$PATH_W'",
  "tls": "tls",
  "sni": "'$ARGO_DOMAIN'"
}'

# 链接2：自动模式 (Address: 隧道域名)
VMESS_JSON_AUTO='{
  "v": "2",
  "ps": "Argo_自动_'$(hostname)'",
  "add": "'$ARGO_DOMAIN'",
  "port": "443",
  "id": "'$UUID'",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "'$ARGO_DOMAIN'",
  "path": "'$PATH_W'",
  "tls": "tls",
  "sni": "'$ARGO_DOMAIN'"
}'

VMESS_LINK_CF="vmess://$(echo -n $VMESS_JSON_CF | base64 -w 0)"
VMESS_LINK_AUTO="vmess://$(echo -n $VMESS_JSON_AUTO | base64 -w 0)"

# 7. 输出结果
echo -e "${GREEN}==========================================================${PLAIN}"
echo -e "${GREEN}部署成功！${PLAIN}"
echo -e ""
echo -e "UUID:   ${YELLOW}$UUID${PLAIN}"
echo -e "Path:   ${YELLOW}$PATH_W${PLAIN}"
echo -e "Domain: ${YELLOW}$ARGO_DOMAIN${PLAIN}"
echo -e ""
echo -e "${GREEN}----------------------------------------------------------${PLAIN}"
echo -e "节点 1 (推荐): 使用 speed.cloudflare.com 优选 IP (复制下方链接)"
echo -e "${YELLOW}$VMESS_LINK_CF${PLAIN}"
echo -e "${GREEN}----------------------------------------------------------${PLAIN}"
echo -e "节点 2 (备用): 使用自动域名 (复制下方链接)"
echo -e "${YELLOW}$VMESS_LINK_AUTO${PLAIN}"
echo -e "${GREEN}==========================================================${PLAIN}"

# 保存链接到文件方便查看
echo $VMESS_LINK_CF > vmess_cf.txt
echo $VMESS_LINK_AUTO > vmess_auto.txt
echo -e "链接已保存到 vmess_cf.txt 和 vmess_auto.txt"
