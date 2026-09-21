# ======================================================================
# 5. CodePipeline 서비스 IAM Role
# ======================================================================
# IAM은 글로벌 서비스라 리전 상관없이 기본 provider(aws) 사용

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.tag_header}AmazonCodePipelineService-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# CodePipeline 실행 권한 (S3, CodeBuild, CodeDeploy 액세스)
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.tag_header}CodePipelineServicePolicy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketVersioning", "s3:PutObjectAcl", "s3:PutObject"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ]
        Resource = "*"
      }
    ]
  })
}

# ======================================================================
# 6. Pipeline Artifacts 저장용 S3 Bucket
# ======================================================================
# Source(도쿄)와 Deploy(오사카) 두 리전에서 동작하는 cross-region 파이프라인이라
# 각 리전마다 아티팩트 버킷이 하나씩 필요합니다.

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 파이프라인 기본(홈) 리전 - 도쿄
resource "aws_s3_bucket" "pipeline_bucket" {
  provider      = aws.tokyo
  bucket        = "${var.tag_header}pipeline-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Deploy 액션이 실행되는 오사카 리전용 복제 버킷
resource "aws_s3_bucket" "pipeline_bucket_osaka" {
  bucket        = "${var.tag_header}pipeline-artifacts-osaka-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# ======================================================================
# 연결 작업 - AWS <-> GitHub 간 CodeStar Connection 생성
# ======================================================================
# 오사카 리전에서는 CodeStar Connections(CodeConnections) 서비스 자체가
# 지원되지 않아, 지원되는 도쿄 리전에 연결을 생성합니다.
resource "aws_codestarconnections_connection" "github" {
  provider      = aws.tokyo
  name          = "${var.tag_header}github-connection"
  provider_type = "GitHub"
}

# ======================================================================
# 7. AWS CodePipeline 생성 (도쿄 리전, Deploy만 오사카로 cross-region)
# ======================================================================

resource "aws_codepipeline" "codepipeline" {
  provider = aws.tokyo
  name     = "${var.tag_header}asg-cicd-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  # cross-region 액션(Deploy)이 있어서 리전별로 artifact_store를 따로 지정
  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
    region   = "ap-northeast-1"
  }

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket_osaka.bucket
    type     = "S3"
    region   = "ap-northeast-3"
  }

  # Stage 1: Source (도쿄 리전의 GitHub CodeStar Connection 기준)
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      region           = "ap-northeast-1"

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repository_id
        BranchName       = var.github_branch
      }
    }
  }

  # Stage 2: Deploy (오사카 리전의 CodeDeploy ASG 배포로 cross-region 실행)
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"
      region          = "ap-northeast-3"

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
}