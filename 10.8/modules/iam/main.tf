# ==================================================================
# EC2용 S3 FullAccess 역할 + 인스턴스 프로파일
# ==================================================================
resource "aws_iam_role" "std17_s3_fullaccess_role" {
  name = "std17-s3-fullaccess-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "std17-s3-fullaccess-role" }
}

resource "aws_iam_role_policy_attachment" "std17_s3_fullaccess_attach" {
  role       = aws_iam_role.std17_s3_fullaccess_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "std17_s3_fullaccess_profile" {
  name = "std17-s3-fullaccess-profile"
  role = aws_iam_role.std17_s3_fullaccess_role.name
}