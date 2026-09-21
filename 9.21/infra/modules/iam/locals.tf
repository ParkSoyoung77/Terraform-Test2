# modules/iam/locals.tf
locals {
    ec2_policy_arns = toset([
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
    ])
}