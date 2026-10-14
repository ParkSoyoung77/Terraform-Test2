#!/bin/bash
# Amazon Linux 2023 : Docker + nginx 컨테이너 + CloudWatch Agent
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

# ── 1. 패키지 업데이트 및 설치 ─────────────────────────
dnf update -y
dnf install -y docker unzip amazon-cloudwatch-agent stress-ng httpd-tools

systemctl enable --now docker
usermod -aG docker ec2-user

# ── 2. 인스턴스 정보 조회 (IMDSv2) ─────────────────────
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# ── 3. nginx 기본 페이지 (ALB 분산 확인용) ──────────────
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

# ── 4. nginx 컨테이너 실행 (호스트 80 -> 컨테이너 80) ───
docker run -d \
  --name nginx \
  --restart always \
  -p 80:80 \
  -v /opt/nginx/html:/usr/share/nginx/html:ro \
  nginx:stable

# ── 5. Docker Compose 플러그인 (실패해도 계속 진행) ─────
DOCKER_PLUGIN_DIR="/usr/libexec/docker/cli-plugins"
mkdir -p "$DOCKER_PLUGIN_DIR"
curl -fSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o "$DOCKER_PLUGIN_DIR/docker-compose" \
  && chmod +x "$DOCKER_PLUGIN_DIR/docker-compose" \
  || echo "WARN: docker compose 설치 실패"

# ── 6. CloudWatch Agent 설정 ──────────────────────────
mkdir -p /opt/aws/amazon-cloudwatch-agent/bin/
cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "namespace": "CWAgent",
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "InstanceId": "${aws:InstanceId}"
    },
    "aggregation_dimensions": [["AutoScalingGroupName"]],
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected":{
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog", 
            "log_group_name": "std17-system-syslog", 
            "log_stream_name": "{instance_id}" 
          }
        ]
      }
    }
  }
}
EOF

# ── 7. CloudWatch Agent 구동 ──────────────────────────
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s