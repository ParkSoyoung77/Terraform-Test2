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

sudo tee /opt/gitlab/docker-compose.yaml > /dev/null << 'EOF'
version: '3.8'
services:
  web:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    hostname: '56.155.28.109'   # 호스트의 IP 또는 ALB와 연결된 도메인(+ protocol)

    # 컨테이너 내부 환경 변수
    environment:
      GITLAB_OMNIBUS_CONFIG: | # gitlab 설정 파일(gitlab.rb)에 들어갈 내용
        external_url 'http://56.155.28.109' # 프로토콜을 포함한 호스트의 IP 또는 ALB와 연결된 도메인

        # SSH 포트번호 변경(인스턴스의 SSH와 충돌 방지)
        gitlab_rails['gitlab_shell_ssh_port'] = 2222 # 보안 그룹의 인바운드 Allow 포트번호와 일치해야 함

        # 메모리 절약
        puma['worker_processes'] = 2      # 웹 서버 프로세스의 수 제한 (메모리 사용량 제한)
        sidekiq['max_concurrency'] = 10   # 백그라운드 작업 처리 스레드 수 제한
        prometheus_monitoring['enable'] = false # 프로메테우스 모니터링 비활성화 (메모리 절약)

    ports: # environment와 동일 Level
      - '80:80'
      - '443:443'
      - '2222:22' # 외부에서 들어온 2222번 포트를 내부 포트 22번과 연결

    volumes:
      - '/opt/gitlab/config:/etc/gitlab'
      - '/opt/gitlab/logs:/var/log/gitlab'
      - '/opt/gitlab/data:/var/opt/gitlab'

    shm_size: '256m' #  컨테이너의 공유 메모리(기본메모리, /dev/shm)의 크기를 256MB로 확장 (기본 64MB)
EOF

sudo chown ec2-user:ec2-user /opt/gitlab/docker-compose.yaml

# 8. GitLab 컨테이너 실행
sudo docker compose -f /opt/gitlab/docker-compose.yaml up -d