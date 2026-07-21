resource "aws_ecr_repository" "client_webapp" {
  name                 = "${var.name}-${var.environment}-client-webapp"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-${var.environment}-client-webapp"
  })
}
