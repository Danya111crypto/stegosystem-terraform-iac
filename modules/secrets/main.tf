variable "environment" { type = string }
variable "rotation_days" {
  type    = number
  default = 30
}

resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.environment}/stegosystem/db-credentials"
  description             = "Динамічні облікові дані PostgreSQL із політикою ротації ${var.rotation_days} днів"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username      = "stego_admin"
    password      = random_password.db_password.result
    engine        = "postgres"
    port          = 5432
    rotation_days = var.rotation_days
  })
}

output "secret_arn" { value = aws_secretsmanager_secret.db_credentials.arn }
output "db_username" { value = "stego_admin" }
output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}