#!/bin/bash

# =========================================================
# Sub-Store + Caddy (Docker) 一键部署脚本
# 作者: SIJULY (基于你的需求定制)
# 功能: 自动检测Docker, 交互式配置域名/Cloudflare, 自动部署
# =========================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 检查是否为 Root 用户
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误: 必须使用 root 用户运行此脚本。${PLAIN}" 
   exit 1
fi

echo -e "${GREEN}正在初始化环境检测...${PLAIN}"

# 1. 检查并安装 Docker & Docker Compose
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}未检测到 Docker，正在安装...${PLAIN}"
    curl -fsSL https://get.docker.com | bash -s docker
    systemctl enable --now docker
else
    echo -e "${GREEN}Docker 已安装。${PLAIN}"
fi

# 确保 Docker Compose 插件可用
if ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: 未检测到 Docker Compose 插件 (docker compose)。请确保安装了最新版 Docker。${PLAIN}"
    exit 1
fi

# 2. 交互式收集信息
echo -e "\n${YELLOW}=== 配置向导 ===${PLAIN}"

# 设置安装目录
INSTALL_DIR="/opt/sub-store-docker"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 获取域名
read -p "请输入你的域名 (例如 sub.example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}错误: 域名不能为空${PLAIN}"
    exit 1
fi

# 获取 Cloudflare Token (可选)
echo -e "\n是否使用 Cloudflare API 自动申请证书? (推荐)"
echo -e "如果不使用，Caddy 将尝试使用 HTTP 验证 (需要 80 端口开放且无防火墙阻挡)"
read -p "输入 y 使用 Cloudflare，输入 n 不使用 [y/n]: " USE_CF

CF_TOKEN=""
if [[ "$USE_CF" == "y" || "$USE_CF" == "Y" ]]; then
    read -p "请输入 Cloudflare API Token (Edit Zone DNS 权限): " CF_TOKEN
fi

# 生成 Sub-Store 安全 Token
SUB_TOKEN=$(openssl rand -hex 16)
echo -e "\n${GREEN}已自动生成 Sub-Store 后端安全路径: /${SUB_TOKEN}${PLAIN}"

# 3. 生成配置文件

echo -e "\n${GREEN}正在生成配置文件...${PLAIN}"

# --- 生成 Dockerfile (用于构建带插件的 Caddy) ---
cat > Dockerfile <<EOF
FROM caddy:builder AS builder

RUN xcaddy build \\
    --with github.com/caddy-dns/cloudflare

FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
EOF

# --- 生成 docker-compose.yml ---
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  sub-store:
    image: xream/sub-store:latest
    container_name: sub-store
    restart: always
    volumes:
      - ./data:/opt/app/data
    environment:
      - SUB_STORE_FRONTEND_BACKEND_PATH=/${SUB_TOKEN}
    networks:
      - sub-store-net

  caddy:
    build: .
    container_name: caddy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    environment:
      - CF_API_TOKEN=${CF_TOKEN}
    networks:
      - sub-store-net

volumes:
  caddy_data:
  caddy_config:

networks:
  sub-store-net:
EOF

# --- 生成 Caddyfile ---
# 根据是否使用 CF 决定配置内容
if [[ -n "$CF_TOKEN" ]]; then
    # 使用 Cloudflare DNS 验证
    cat > Caddyfile <<EOF
${DOMAIN} {
    tls {
        dns cloudflare {env.CF_API_TOKEN}
    }
    reverse_proxy sub-store:3001
    encode gzip
}
EOF
else
    # 使用普通 HTTP 验证
    cat > Caddyfile <<EOF
${DOMAIN} {
    reverse_proxy sub-store:3001
    encode gzip
}
EOF
fi

# 4. 启动服务
echo -e "\n${GREEN}正在构建并启动服务 (首次构建 Caddy 可能需要几分钟)...${PLAIN}"
docker compose up -d --build

# 5. 输出结果
if [ $? -eq 0 ]; then
    echo -e "\n========================================================"
    echo -e " ${GREEN}Sub-Store 部署成功!${PLAIN}"
    echo -e "========================================================"
    echo -e " 访问地址 (请妥善保存，包含密钥):"
    echo -e " ${YELLOW}https://${DOMAIN}?api=https://${DOMAIN}/${SUB_TOKEN}${PLAIN}"
    echo -e "========================================================"
    echo -e " 安装目录: ${INSTALL_DIR}"
    echo -e " 如需查看日志: cd ${INSTALL_DIR} && docker compose logs -f"
else
    echo -e "\n${RED}部署失败，请检查上方错误信息。${PLAIN}"
fi
