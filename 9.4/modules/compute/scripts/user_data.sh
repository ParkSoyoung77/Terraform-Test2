#!/bin/bash
set -e

# ===== 설치 =====
apt update -y
apt install -y nginx
systemctl enable nginx
systemctl start nginx