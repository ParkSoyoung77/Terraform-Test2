#!/bin/bash
set -e

# ====================================================
# 기본 패키지 설치
# ====================================================
apt-get update -y
apt-get install -y curl unzip apt-transport-https ca-certificates gnupg lsb-release

# ====================================================
# Docker 설치 (공식 저장소)
# ====================================================
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ubuntu 유저가 sudo 없이 docker 사용 가능하도록
usermod -aG docker ubuntu

systemctl enable docker
systemctl start docker