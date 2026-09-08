# data "aws_ami" "std17_ex_nginx_ami" {
#     most_recent = true
#     owners      = ["self"]

#     # Name 태그 검색
#     filter {
#         name = "tag:Name"
#         values = ["std17-ex-nginx-ami"]
#     }

#     # Class 태그 검색
#     filter {
#         name = "tag:Class"
#         values = ["bipa17"]
#     }

#     # Owner 태그 검색
#     filter {
#         name = "tag:Owner"
#         values = ["std17"]
#     }
# }