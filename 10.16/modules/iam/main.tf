resource "aws_iam_role" "std17_ec2_role" {
    name = "${var.name_prefix}-ec2-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = {
        Name = "${var.name_prefix}-ec2-role"
    }
}

# ECR 이미지 pull
resource "aws_iam_role_policy_attachment" "std17_ec2_ecr_readonly" {
    role       = aws_iam_role.std17_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# SSM Session Manager 접속
resource "aws_iam_role_policy_attachment" "std17_ec2_ssm_core" {
    role       = aws_iam_role.std17_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent: 지표/로그 전송 + EC2 태그 조회
resource "aws_iam_role_policy_attachment" "std17_ec2_cw_agent" {
    role       = aws_iam_role.std17_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "std17_ec2_profile" {
    name = "${var.name_prefix}-ec2-instance-profile"
    role = aws_iam_role.std17_ec2_role.name
}