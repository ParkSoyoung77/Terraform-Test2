resource "aws_s3_bucket" "trraform_state" {
    bucket = "std17-instructor-terraform-state-bucket"

    lifecycle {
        prevent_destroy = true
    }

    tags={
        Name = "std17-ex-terraform-state-bucket"
    }
}