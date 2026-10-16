locals {
    fastapi_setup = templatefile("${path.module}/scripts/fastapi_setup.sh.tftpl", {
        main_py         = file("${path.module}/app/main.py")
        dockerfile      = file("${path.module}/app/Dockerfile")
        compose_yml     = file("${path.module}/app/docker-compose.yml")
        requirements    = file("${path.module}/app/requirements.txt")
        fastapi_service = file("${path.module}/scripts/fastapi.service")
        config_json     = jsonencode({
            region      = var.aws_region
            lambda_name = var.lambda_function_name
        })
    })
}