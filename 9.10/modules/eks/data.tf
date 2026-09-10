data "aws_ami" "eks_ami" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS 공식 계정

  filter {
    name   = "name"
    # 'standard'를 명시하는 대신 와일드카드를 써서 1.35 버전의 x86_64 이미지를 찾습니다.
    values = ["amazon-eks-node-al2023-x86_64-standard-1.35-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}