# Cloudflare Tunnel + Xray 一键脚本 (修复版)

这是一个专为 NAT 机器、动态 IP 或无公网 IP 环境设计的 Vmess 直连脚本。
基于 Cloudflare Argo Tunnel 技术，实现内网穿透。

## ✨ 特点
- [x] 修复了原版 JSON 格式错误，Nekobox/V2rayNG 可直接识别
- [x] 自动生成标准 Vmess 链接
- [x] 双模式输出：提供「优选 IP 模式」和「自动域名模式」
- [x] 自动识别 AMD64 / ARM64 架构
- [x] 纯净无后台残留（使用 nohup 后台运行）

## 🚀 使用方法
在 SSH 终端执行以下命令：

bash
wget -N https://raw.githubusercontent.com/qq540187000/suoha-fixed/main/install.sh && bash install.sh


## 🛠 客户端设置
脚本运行结束后，会输出两个 `vmess://` 链接：
1. **优选 IP 模式 (推荐)**：自动配置了 `speed.cloudflare.com`，速度更快。
2. **自动模式**：直接使用 Tunnel 域名，连通性更好。

复制链接导入 Nekobox 即可使用。
