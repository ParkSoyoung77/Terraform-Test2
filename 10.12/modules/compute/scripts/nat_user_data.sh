#!/bin/bash
# ==========================================================
# NAT 인스턴스 User Data (Amazon Linux 2023)
# - root로 실행되므로 sudo 불필요
# - 템플릿 변수 없음 → Terraform에서 file() 로 그대로 읽음
#   (그래서 bash 변수를 평소처럼 ${VAR} / $VAR 로 써도 됨)
# ==========================================================

# 1. 패키지 설치
#    iptables-services : NAT 규칙 영구 저장/부팅 시 자동 로드
#    mariadb105        : 프라이빗 DB 접속 테스트용 클라이언트
dnf update -y
dnf install -y iptables-services mariadb105

# 2. IP 포워딩 활성화 (재부팅 후에도 유지)
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-ip-forward.conf
sysctl -p /etc/sysctl.d/99-ip-forward.conf

# 3. 기본 네트워크 인터페이스 자동 감지 (Nitro 인스턴스는 보통 ens5)
IFACE=$(ip route | awk '/^default/ {print $5; exit}')

# 4. iptables 서비스 시작 후 기본 규칙 초기화
#    iptables-services 기본 규칙은 SSH 외 INPUT/FORWARD를 REJECT하므로 비움
#    (트래픽 필터링은 보안 그룹이 담당)
systemctl enable --now iptables
iptables -F
iptables -t nat -F

# 5. NAT 규칙
iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
# -i(IFACE)로 들어오는 패킷을 -o(IFACE)로 전달하도록 허용
iptables -A FORWARD -i "$IFACE" -o "$IFACE" -j ACCEPT

# 6. 규칙 영구 저장 (부팅 시 iptables 서비스가 자동 로드)
iptables-save > /etc/sysconfig/iptables