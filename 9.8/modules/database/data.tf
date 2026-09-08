# data "aws_subnet" "subnet_ids" {
#     filter {
#         name   = "vpc-id"
#         value  = ["vpc_id"]
#     }

#     filter {
#         name   = "tag:Name"
#         values = [
#             # 서브넷 모음
#         ]
#     }
# }