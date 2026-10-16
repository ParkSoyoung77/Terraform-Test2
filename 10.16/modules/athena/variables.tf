variable "name_prefix" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "log_bucket_name" {
  description = "CloudTrail 로그가 저장된 S3 버킷 (Athena 결과도 여기 저장)"
  type        = string
}

variable "aws_region" {
  description = "CloudTrail 로그 경로의 리전"
  type        = string
}

variable "cloudtrail_columns" {
  description = "CloudTrail 테이블 컬럼 (Glue는 소문자 컬럼명)"
  type        = list(object({ name = string, type = string }))
  default = [
    { name = "eventversion", type = "string" },
    { name = "useridentity", type = "struct<type:string,principalid:string,arn:string,accountid:string,invokedby:string,accesskeyid:string,username:string,sessioncontext:struct<attributes:struct<mfaauthenticated:string,creationdate:string>,sessionissuer:struct<type:string,principalid:string,arn:string,accountid:string,username:string>>>" },
    { name = "eventtime", type = "string" },
    { name = "eventsource", type = "string" },
    { name = "eventname", type = "string" },
    { name = "awsregion", type = "string" },
    { name = "sourceipaddress", type = "string" },
    { name = "useragent", type = "string" },
    { name = "errorcode", type = "string" },
    { name = "errormessage", type = "string" },
    { name = "requestparameters", type = "string" },
    { name = "responseelements", type = "string" },
    { name = "additionaleventdata", type = "string" },
    { name = "requestid", type = "string" },
    { name = "eventid", type = "string" },
    { name = "readonly", type = "string" },
    { name = "resources", type = "array<struct<arn:string,accountid:string,type:string>>" },
    { name = "eventtype", type = "string" },
    { name = "apiversion", type = "string" },
    { name = "recipientaccountid", type = "string" },
    { name = "serviceeventdetails", type = "string" },
    { name = "sharedeventid", type = "string" },
    { name = "vpcendpointid", type = "string" },
  ]
}