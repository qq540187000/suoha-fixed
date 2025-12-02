# Cloudflare Tunnel + Xray 一键脚本 (修复版)

这是一个专为 **NAT 机器**、**动态 IP** 或 **无公网 IP** 环境设计的 Xray + Argo Tunnel 脚本。
本脚本基于原版进行了重构，修复了 JSON 格式错误、UUID 乱码等问题，生成的链接可直接导入 Nekobox 或 V2RayNG 使用。

## ✨ 项目特点
- [x] **自动修复配置**：生成标准的 VMess 协议配置，拒绝 `vmess://` 导入失败。
- [x] **智能架构识别**：自动检测并下载适合 AMD64 或 ARM64 的程序。
- [x] **双模式输出**：同时生成「优选 IP 模式」（速度快）和「自动域名模式」（连通性好）。
- [x] **稳定后台运行**：使用 nohup 守护进程，关闭 SSH 窗口后节点依然在线。
- [x] **自定义端口**：随机生成本地端口，避免端口冲突。

## 🚀 一键安装命令

在 SSH 终端复制并运行以下命令即可：

```bash
wget -N https://raw.githubusercontent.com/qq540187000/suoha-fixed/main/install.sh && bash install.sh

## 🗑 卸载方法

如果你想停止服务并清理所有文件，请运行：

```bash
wget -N [https://raw.githubusercontent.com/qq540187000/suoha-fixed/main/uninstall.sh](https://raw.githubusercontent.com/qq540187000/suoha-fixed/main/uninstall.sh) && bash uninstall.sh

