provider "aws" {
    region = var.aws_region

    default_tags {
        tags = {
            Owner    = "std17-test"
            Class    = "bipa17"
            ManageBy = "Terraform"
        }
    }
}
