resource "aws_iam_role" "node_role_asg" {
    name = "${var.tag_header}AmazonASGNodeEC2-Role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect    = "Allow"
                Principal = { Service = "ec2.amazonaws.com" }
                Action    = "sts:AssumeRole"    # 신뢰관계 허용(IAM Role을 임시로 획득하여 권한을 행사, 임시권한 허용)
            }
        ]
    })
}

# 정책 연결
resource "aws_iam_role_policy_attachment" "node_policies_asg" {
    for_each = local.ec2_policy_arns

    role       = aws_iam_role.node_role_asg.name
    policy_arn = each.value
}

# 인스턴스 프로필 생성
resource "aws_iam_instance_profile" "node_profile_asg" {
    name = "${var.tag_header}ASGNodeInstance-profile"
    role = aws_iam_role.node_role_asg.name
}

