# AWS 관리형 정책 연결
locals {
  std17_s3_bucket_function_managed_policies = toset([
    "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ])
}

resource "aws_iam_role_policy_attachment" "std17_s3_bucket_function_managed" {
  for_each = local.std17_s3_bucket_function_managed_policies

  role       = aws_iam_role.std17_s3_bucket_function_role.name
  policy_arn = each.value
}