#!/bin/bash

# 1. 패키지 설치
sudo dnf update -y
sudo dnf install -y docker git wget parted

# 2. Docker 시작 및 권한 부여
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# 3. Docker Compose v2 설치
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# 4. Swap 설정
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# 5. 추가 볼륨 포맷 및 /opt/gitlab 마운트
sudo mkdir -p /opt/gitlab

if ! sudo blkid /dev/nvme1n1 > /dev/null 2>&1; then
    sudo mkfs -t ext4 /dev/nvme1n1
fi

sudo mount /dev/nvme1n1 /opt/gitlab
echo '/dev/nvme1n1 /opt/gitlab ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# 6. 하위 디렉토리 생성 및 권한 설정
sudo mkdir -p /opt/gitlab/{config,logs,data}
sudo chown -R ec2-user:ec2-user /opt/gitlab

# 7. GitLab 설정
cd /opt/gitlab