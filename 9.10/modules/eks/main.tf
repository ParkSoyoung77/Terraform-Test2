# ======================================================
# EKS 구축 프로세스: 네트워크 구성 -> IAM 권한 설정 
# -> EKS 클러스터 구성 -> 노드 그룹 정의 -> 액세스 환경정의
# ======================================================
# 서브넷 공통: "kubernetes.io/cluster/<EKS이름>" = "shared"
# 퍼블릭 서브넷: "kubernetes.io/role/elb" = "1"
# 프라이빗 서브넷: "kubernetes.io/role/internal-elb" = "1"
# ======================================================

# ======================================================
# 1. EKS 및 워커노드를 위한 보안 그룹 생성
# 노드와 컨트롤 플레인(k8s master) 간 통신을 위한 포트:10250/tcp
# 노드 간 통신 모두 열어줌
# ======================================================
resource "aws_security_group" "std17_eks_sg" {
    name = "${var.tag_header}eks-sg"
    description = "Security group for EKS access"
    vpc_id = var.vpc_id

    ingress {
        description = "SG for WorkerNode"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
    }

    ingress {
        from_port   = 10250
        to_port     = 10250
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.tag_header}eks-sg"
    }
}

# ======================================================
# 2. k8s master 및 워커 노드용 역할 및 정책 생성
# 클러스터(k8s)로 역할(role) 생성
# ======================================================
resource "aws_iam_role" "cluster_role" {
    name = "${local.tag_header}eks-cluster-role"
    assume_role_policy = jsonencode ({
        Version   = "2012-10-17",
        Statement = [
            {
                Action    = "sts:AssumeRole",
                Effect    = "Allow",
                Principal = { Service = "eks.amazonaws.com"}
            }
        ]
    })
}

# 역할에서 사용할 정책 연결
# 정책연결: 콘솔(IAM-Policy) AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.cluster_role.name
}

# ======================================================
# 워커노드용 역할 및 정책
resource "aws_iam_role" "node_role" {
    name = "${local.tag_header}eks-node-role"
    assume_role_policy = jsonencode ({
        Version   = "2012-10-17",
        Statement = [
            {
                Action    = "sts:AssumeRole",
                Effect    = "Allow",
                Principal = { Service = "eks.amazonaws.com"}
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
    for_each   = toset(local.node_policies)
    policy_arn = each.value
    role       = aws_iam_role.node_role.name
}

# ======================================================
# 3. EKS Cluster 리소스 생성
# ======================================================
resource "aws_eks_cluster" "k8s" {
    name = "${local.tag_header}eks-cluster"

    # 클러스터 역할
    role_arn = aws_iam_role.cluster_role.arn

    # 네트워크 설정
    vpc_config {
        subnet_ids = var.private_subnet_ids
    }

    # 사용자 연결 설정
    access_config {
        # EKS 클러스터가 사용자나 역할을 어떤 방식으로 인식하게 할지 지정
        # API_AND_CONFIG_MAP / ConfigMap
        authentication_mode = "API_AND_CONFIG_MAP"
        
        # 생성자에게 자동으로 관리자 권할을 부여
        bootstrap_cluster_creator_admin_permissions = true
    }
}