#!/bin/bash
set -e

# ===== 설치 =====
apt update -y
apt install -y nginx:3.13.3-alpine
systemctl enable nginx
systemctl start nginx