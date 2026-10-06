# ---------------------------------------------------------
# EC2 (S3 FullAccess 접근용 - 백업용)
# ---------------------------------------------------------
resource "aws_iam_role" "std17_s3_fullaccess_role" {
  name        = var.fullaccess_role_name
  description = var.role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, { Name = var.fullaccess_role_name })   # Name이 덮어써지지 않도록 순서 변경
}

resource "aws_iam_role_policy_attachment" "std17_s3_fullaccess_attach" {
  role       = aws_iam_role.std17_s3_fullaccess_role.name
  policy_arn = var.fullaccess_policy_arn
}

resource "aws_iam_instance_profile" "std17_s3_fullaccess_profile" {
  name = var.fullaccess_role_name
  role = aws_iam_role.std17_s3_fullaccess_role.name
}