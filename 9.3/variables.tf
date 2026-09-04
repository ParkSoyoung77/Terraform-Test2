variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "azs" {
    description = "사용할 가용영역 리스트"
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}

variable "name_prefix" {
    description = "모든 리소스 Name/Tag 접두사"
    type        = string
    default     = "std17-test-"
}

variable "subnet_info" {
    description = "AWS subnet Info"
    type        = list(map(string))
    default     = [
        {
            name = "subnet-1"
            cidr = "10.0.1.0/24"
        },
        {
            name = "subnet-2"
            cidr = "10.0.2.0/24"
        }
    ]
}

variable "tup" {
    description = "tuple"
    type        = tuple([string, number, number, number])
    default     = [
        "홍길동", 100, 90, 80
    ]
}

variable "obj" {
    type = object({ # 초기값
        vpc_id   = optional(string,"") 
        vpc_cidr = optional(string,"")
    })

    default = { # 디폴트값
        vpc_id   = ""
    }
}