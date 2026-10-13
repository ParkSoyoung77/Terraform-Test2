#!/bin/bash
# Amazon Linux 2023 : Docker 설치 후 nginx 컨테이너 실행
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

# ── Docker 설치 ───────────────────────────────────
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# ── 인스턴스 정보 조회 (IMDSv2) ─────────────────────
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# ── nginx 기본 페이지 (ALB 분산 확인용으로 인스턴스/AZ 표시) ──
mkdir -p /opt/nginx/html
cat > /opt/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>std17 nginx</title></head>
<body>
  <h1>std17 nginx container on Amazon Linux 2023</h1>
  <p>Instance: $INSTANCE_ID</p>
  <p>AZ: $AZ</p>
</body>
</html>
HTML

# ── nginx 컨테이너 실행 (호스트 80 -> 컨테이너 80) ────
docker run -d \
  --name nginx \
  --restart always \
  -p 80:80 \
  -v /opt/nginx/html:/usr/share/nginx/html:ro \
  nginx:stable
