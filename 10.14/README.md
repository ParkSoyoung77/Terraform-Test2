# std17-test Terraform

요구사항
1. **Nginx Container - ASG/ALB - Amazon Linux(t3.micro, 10GB), Docker**
2. **RDB - MySQL, Instance** (RDS MySQL 단일 DB 인스턴스)
3. **EKS**

## 구성

| 모듈 | 내용 |
|---|---|
| network | VPC 10.0.0.0/16, public 3 / private 3 / EKS 전용 private 3, IGW, NAT 1, S3 Gateway Endpoint |
| security | ALB SG(80) → EC2 SG(ALB에서 80만) → RDS SG(EC2에서 3306) |
| iam | EC2 인스턴스 프로파일 (SSM 접속, ECR pull) |
| alb | 인터넷 ALB, HTTP 80 리스너 → nginx 타겟그룹 |
| compute | Launch Template(AL2023, t3.micro, 루트 gp3 10GB, user_data로 Docker 설치 + nginx 컨테이너) + ASG(프라이빗 서브넷, 1/2/3) |
| rds | RDS MySQL 8.4 db.t4g.micro 단일 인스턴스, 프라이빗 서브넷, 비밀번호는 Secrets Manager |
| eks | EKS 1.34 클러스터 + 관리형 노드그룹(t3.small 1/1/2) + vpc-cni/coredns/kube-proxy 애드온 + 관리자 Access Entry |

트래픽 흐름: `Internet → ALB(:80) → EC2(Amazon Linux 2023, :80) → Docker nginx 컨테이너(:80)`

## 확인

```bash
terraform output alb_url            # 브라우저로 접속, 새로고침하면 Instance/AZ가 바뀜
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

EC2 접속은 SSM Session Manager로: `docker ps`, `cat /var/log/user-data.log`

## 원본 대비 제거한 것 (필요하면 다시 추가)
API Gateway, Lambda, domain-s3 / static-site S3, ACM + HTTPS 리스너, RDS Proxy,
배포 아티팩트 S3 + docker-compose, EKS OIDC / AWS Load Balancer Controller(helm), kubernetes/helm/tls provider
