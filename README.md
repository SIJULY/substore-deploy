# Sub-Store Docker One-Click Deploy

这是一个基于 Docker 和 Caddy 的 Sub-Store 一键部署脚本。

无需繁琐的手动配置，通过简单的交互式脚本，即可在 VPS 上快速搭建带有自动 HTTPS（Let’s Encrypt）支持的 Sub-Store 服务。

***🙏感谢sub-store原作者，本人只是作为小白修改了下部署方式，争取做到对小白相对简单的部署！***

---

# ✨ 特性（Features）
	•	🐳 纯净环境：基于 Docker 容器化部署，不污染宿主机环境，易于卸载。
	•	🔒 自动 HTTPS：集成 Caddy v2，自动申请并续期 SSL 证书。
	•	☁️ 灵活验证：
	•	标准模式（HTTP-01）：无需额外配置，适合普通 VPS。
	•	Cloudflare 模式（DNS-01）：支持隐藏源站 IP、纯内网环境或开启 CDN 的场景。
	•	🛡️ 安全加固：自动生成高强度随机 Token 作为后端访问路径。
	•	⚡ 自动构建：使用 Docker 多阶段构建，自动编译包含 Cloudflare 插件的 Caddy，无需手动安装 Go 环境。

---

# 🛠 前置要求（Prerequisites）
	1.	一台 Linux VPS（Debian / Ubuntu / CentOS 等）。
	2.	Root 权限（脚本会自动安装 Docker）。
	3.	一个域名，并已解析到服务器 IP。
	4.	端口开放：请确保服务器防火墙（Security Group）已放行 80 和 443 端口。

---

# 🚀 快速开始（Quick Start）

在服务器终端执行以下命令即可启动安装：
```bash
bash <(curl -sL https://raw.githubusercontent.com/SIJULY/substore-deploy/main/install.sh)
```

---

# 📋 安装流程说明
	1.	环境检测
	•	脚本会自动检查并安装 Docker & Docker Compose。
	2.	输入域名
	•	输入已正确解析到本机 IP 的域名（例如：sub.example.com）。
	3.	选择证书模式
	•	输入 n（默认 / 推荐）：
	•	使用标准 HTTP-01 验证
	•	要求：域名已解析到本机 IP，且 80 端口必须开放
	•	输入 y（高级）：
	•	使用 Cloudflare API（DNS-01） 验证
	•	要求：域名托管在 Cloudflare，需要提供 API Token
	•	适合开启了“小黄云（CDN）”的用户
	4.	自动部署
	•	脚本将自动生成配置文件并启动相关容器。

---
# 🔑 配置指南：获取 Cloudflare API Token

如果在安装时选择了 Cloudflare 验证模式（y），请按以下步骤获取 API Token：
	1.	登录 Cloudflare 控制台。
	2.	点击右上角头像 → My Profile（我的个人资料）。
	3.	左侧菜单选择 API Tokens → Create Token（创建令牌）。
	4.	选择模板 Edit zone DNS，点击 Use template。
	5.	权限配置：
	•	权限保持默认：Zone / DNS / Edit
	6.	Zone Resources（区域资源）：
	•	在 Include 行选择 Specific zone
	•	右侧下拉框中选择要部署的域名
	7.	点击 Continue to Summary，确认无误后点击 Create Token。

⚠️ 重要：
	•	Token 只会显示一次，请立即复制并在安装脚本中填写。
	
---

# 📝 访问与使用

部署成功后，脚本会输出你的专属访问链接，格式如下：

https://<你的域名>?api=https://<你的域名>/<自动生成的Token>

⚠️ 重要提示：
	•	Sub-Store 依赖 URL 中的 Token 进行身份验证。
	•	请妥善保管该链接，不要泄露给他人。

---
# 📂 维护与管理

安装目录：
```bash
/opt/sub-store-docker
```
常用命令

查看运行日志（排查问题首选）
```bash
cd /opt/sub-store-docker
docker compose logs -f
```
停止服务
```bash
cd /opt/sub-store-docker
docker compose down
```
重启服务
```bash
cd /opt/sub-store-docker
docker compose restart
```
更新 Sub-Store 版本
```bash
cd /opt/sub-store-docker
docker compose pull
docker compose up -d
```
卸载 / 删除
```bash
cd /opt/sub-store-docker
docker compose down
cd ..
rm -rf /opt/sub-store-docker
```

---

# ❓ 常见问题（FAQ）

Q：安装后无法访问，浏览器显示连接超时？
A：请检查云服务商（如 AWS、Oracle、Azure、阿里云等）的 安全组 / 防火墙 设置，必须允许 TCP 80 和 TCP 443 的入站流量。

---

Q：为什么输入了 Cloudflare Token 还是申请失败？
A：请确认以下几点：
	•	Token 权限是否包含 Zone:DNS:Edit
	•	Token 的 Zone Resources 是否包含当前域名
	•	域名是否确实托管在 Cloudflare 上

---

Q：我使用的是免费二级域名（如 .nyc.mn），可以使用 Cloudflare 模式吗？
A：不可以，除非你拥有该域名的 Cloudflare 管理权限。
对于免费二级域名，请在安装时选择 n（不使用 Cloudflare），并确保 80 端口开放。

---

# 🙏 Credits
	•	Core Project：Sub-Store
	•	Web Server：Caddy
