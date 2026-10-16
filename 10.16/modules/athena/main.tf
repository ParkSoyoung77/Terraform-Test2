data "aws_caller_identity" "current" {}

locals {
  account_id     = data.aws_caller_identity.current.account_id
  db_name        = "${var.name_prefix}_trail_db"   # Glue 이름은 소문자/언더스코어
  table_name     = "cloudtrail_logs"
  trail_location = "s3://${var.log_bucket_name}/AWSLogs/${local.account_id}/CloudTrail/${var.aws_region}"
  part_filter    = "\"timestamp\" >= date_format(current_date - interval '1' day, '%Y/%m/%d')"
}

# ==================================================================
# [Athena] 워크그룹 - 쿼리 결과 저장 위치 고정
# ==================================================================
resource "aws_athena_workgroup" "this" {
  name          = "${var.name_prefix}-trail-wg"
  force_destroy = true   # 쿼리 이력이 있어도 destroy 가능

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.log_bucket_name}/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

# ==================================================================
# [Athena] Glue 데이터베이스
# ==================================================================
resource "aws_glue_catalog_database" "this" {
  name = local.db_name
}

# ==================================================================
# [Athena] CloudTrail 테이블 (파티션 프로젝션)
# ==================================================================
resource "aws_glue_catalog_table" "cloudtrail" {
  name          = local.table_name
  database_name = aws_glue_catalog_database.this.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                              = "TRUE"
    "projection.enabled"                  = "true"
    "projection.timestamp.type"           = "date"
    "projection.timestamp.format"         = "yyyy/MM/dd"
    "projection.timestamp.range"          = "2026/10/01,NOW"
    "projection.timestamp.interval"       = "1"
    "projection.timestamp.interval.unit"  = "DAYS"
    # $${timestamp} : Terraform 보간이 아니라 Athena 템플릿 문자 그대로 넣기 위해 $$ 사용
    "storage.location.template"           = "${local.trail_location}/$${timestamp}"
  }

  partition_keys {
    name = "timestamp"
    type = "string"
  }

  storage_descriptor {
    location      = local.trail_location
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
    }

    dynamic "columns" {
      for_each = var.cloudtrail_columns
      content {
        name = columns.value.name
        type = columns.value.type
      }
    }
  }
}

# ==================================================================
# [Athena] 샘플 쿼리 (콘솔 > 저장된 쿼리)
# ==================================================================
resource "aws_athena_named_query" "recent_events" {
  name      = "${var.name_prefix}-recent-events"
  workgroup = aws_athena_workgroup.this.name
  database  = aws_glue_catalog_database.this.name
  query     = <<-SQL
    SELECT eventtime, eventsource, eventname, useridentity.arn AS who, sourceipaddress, awsregion
    FROM ${local.table_name}
    WHERE ${local.part_filter}
    ORDER BY eventtime DESC
    LIMIT 100;
  SQL
}

resource "aws_athena_named_query" "console_login" {
  name      = "${var.name_prefix}-console-login"
  workgroup = aws_athena_workgroup.this.name
  database  = aws_glue_catalog_database.this.name
  query     = <<-SQL
    SELECT eventtime, useridentity.arn AS who, sourceipaddress,
           json_extract_scalar(responseelements, '$.ConsoleLogin') AS result
    FROM ${local.table_name}
    WHERE eventname = 'ConsoleLogin' AND ${local.part_filter}
    ORDER BY eventtime DESC;
  SQL
}

resource "aws_athena_named_query" "access_denied" {
  name      = "${var.name_prefix}-access-denied"
  workgroup = aws_athena_workgroup.this.name
  database  = aws_glue_catalog_database.this.name
  query     = <<-SQL
    SELECT eventtime, eventsource, eventname, useridentity.arn AS who, errorcode, errormessage
    FROM ${local.table_name}
    WHERE errorcode IN ('AccessDenied', 'UnauthorizedOperation', 'Client.UnauthorizedOperation')
      AND ${local.part_filter}
    ORDER BY eventtime DESC;
  SQL
}

resource "aws_athena_named_query" "sg_changes" {
  name      = "${var.name_prefix}-security-group-changes"
  workgroup = aws_athena_workgroup.this.name
  database  = aws_glue_catalog_database.this.name
  query     = <<-SQL
    SELECT eventtime, eventname, useridentity.arn AS who, sourceipaddress, requestparameters
    FROM ${local.table_name}
    WHERE eventname IN ('AuthorizeSecurityGroupIngress', 'RevokeSecurityGroupIngress',
                        'AuthorizeSecurityGroupEgress', 'RevokeSecurityGroupEgress',
                        'CreateSecurityGroup', 'DeleteSecurityGroup')
      AND ${local.part_filter}
    ORDER BY eventtime DESC;
  SQL
}