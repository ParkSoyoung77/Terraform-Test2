variable "tag_header" {
  description = "리소스 이름 접두사 (예: std17-)"
  type        = string
}

variable "routes" {
  description = "경로 이름 => { route_key, function_name, invoke_arn }"
  type = map(object({
    route_key     = string   # 예: "GET /bucket/delete"
    function_name = string
    invoke_arn    = string
  }))
}