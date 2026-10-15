data "aws_caller_identity" "current" {}

locals {
    admin_arns = length(var.admin_principal_arns) > 0 ? var.admin_principal_arns : [data.aws_caller_identity.current.arn]
}

# ==================================================================
# 1. IAM — EKS 클러스터 / 노드그룹 역할
# ==================================================================

resource "aws_iam_role" "std17_test_eks_cluster_role" {
    name = "std17-test-eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "eks.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = { Name = "std17-test-eks-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "std17_test_eks_cluster_policy" {
    role       = aws_iam_role.std17_test_eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "std17_test_eks_node_role" {
    name = "std17-test-eks-node-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = { Name = "std17-test-eks-node-role" }
}

resource "aws_iam_role_policy_attachment" "std17_test_eks_worker_node_policy" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "std17_test_eks_cni_policy" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# 노드에서 ECR 이미지 pull
resource "aws_iam_role_policy_attachment" "std17_test_eks_ecr_readonly" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 디버깅용: SSM Session Manager로 노드 접속, kubelet/hostPath 로그 확인
resource "aws_iam_role_policy_attachment" "std17_test_eks_ssm_core" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==================================================================
# 2. EKS 클러스터
# ==================================================================

resource "aws_eks_cluster" "std17_test_eks" {
    name     = var.cluster_name
    version  = var.cluster_version
    role_arn = aws_iam_role.std17_test_eks_cluster_role.arn

    vpc_config {
        subnet_ids              = var.private_subnet_ids
        endpoint_private_access = true
        endpoint_public_access  = var.endpoint_public_access
        public_access_cidrs     = var.endpoint_public_access_cidrs
    }

    access_config {
        authentication_mode = "API"
    }

    depends_on = [aws_iam_role_policy_attachment.std17_test_eks_cluster_policy]

    tags = { Name = var.cluster_name }
}

# ==================================================================
# 3. 관리형 노드그룹
# ==================================================================

resource "aws_eks_node_group" "std17_test_eks_nodegroup" {
    cluster_name    = aws_eks_cluster.std17_test_eks.name
    node_group_name = var.node_group_name
    node_role_arn   = aws_iam_role.std17_test_eks_node_role.arn
    subnet_ids      = var.private_subnet_ids

    instance_types = var.node_instance_types
    capacity_type  = "ON_DEMAND"
    disk_size      = var.node_disk_size

    scaling_config {
        desired_size = var.node_desired_size
        min_size     = var.node_min_size
        max_size     = var.node_max_size
    }

    update_config {
        max_unavailable = 1
    }

    # 노드 SSH: 키페어 지정 시 EKS가 22번 허용 SG를 만들어 노드에 붙임
    # (주의: remote_access 추가/변경 시 노드그룹이 재생성됨)
    dynamic "remote_access" {
        for_each = var.node_ssh_key_name == null ? [] : [1]
        content {
            ec2_ssh_key               = var.node_ssh_key_name
            source_security_group_ids = var.node_ssh_source_sg_ids
        }
    }

    depends_on = [
        aws_iam_role_policy_attachment.std17_test_eks_worker_node_policy,
        aws_iam_role_policy_attachment.std17_test_eks_cni_policy,
        aws_iam_role_policy_attachment.std17_test_eks_ecr_readonly,
    ]

    tags = { Name = var.node_group_name }
}

# ==================================================================
# 4. 코어 애드온 (VPC CNI, CoreDNS, kube-proxy)
# ==================================================================

resource "aws_eks_addon" "std17_test_vpc_cni" {
    cluster_name  = aws_eks_cluster.std17_test_eks.name
    addon_name    = "vpc-cni"
    addon_version = lookup(var.addon_versions, "vpc-cni", null)

    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    depends_on = [aws_eks_node_group.std17_test_eks_nodegroup]
}

resource "aws_eks_addon" "std17_test_coredns" {
    cluster_name  = aws_eks_cluster.std17_test_eks.name
    addon_name    = "coredns"
    addon_version = lookup(var.addon_versions, "coredns", null)

    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    depends_on = [aws_eks_node_group.std17_test_eks_nodegroup]
}

resource "aws_eks_addon" "std17_test_kube_proxy" {
    cluster_name  = aws_eks_cluster.std17_test_eks.name
    addon_name    = "kube-proxy"
    addon_version = lookup(var.addon_versions, "kube-proxy", null)

    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    depends_on = [aws_eks_node_group.std17_test_eks_nodegroup]
}

# ==================================================================
# 5. Access Entry (관리자 권한 부여)
# ==================================================================

resource "aws_eks_access_entry" "std17_test_admin_entry" {
    count = length(local.admin_arns)

    cluster_name  = aws_eks_cluster.std17_test_eks.name
    principal_arn = local.admin_arns[count.index]
    type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "std17_test_admin_policy" {
    count = length(local.admin_arns)

    cluster_name  = aws_eks_cluster.std17_test_eks.name
    principal_arn = local.admin_arns[count.index]
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope {
        type = "cluster"
    }

    depends_on = [aws_eks_access_entry.std17_test_admin_entry]
}
