variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "app_security_group_id" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Дозволяє доступ до PostgreSQL (5432) виключно від групи безпеки інстансів застосунку"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "postgres" {
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = "t3.small"
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.db.id]
  associate_public_ip_address = false

  user_data = base64encode(<<-EOF
    #!/bin/bash
    export DB_ENGINE="postgres:15.4"
    export DB_NAME="stegosystem"
    export DB_USER="${var.db_username}"
    export BACKUP_RETENTION_DAYS=7
  EOF
  )

  lifecycle {
    ignore_changes = [vpc_security_group_ids, instance_type]
  }

  tags = {
    Name            = "${var.environment}-stegosystem-postgres"
    Engine          = "PostgreSQL-15.4"
    BackupRetention = "7-days"
  }
}

resource "aws_ebs_snapshot" "db_initial_backup" {
  volume_id   = aws_instance.postgres.root_block_device[0].volume_id
  description = "Автоматична резервна копія БД ${var.environment}-stegosystem (retention: 7 днів)"

  tags = {
    Name = "${var.environment}-db-backup-snapshot"
  }
}

output "db_endpoint" { value = "${aws_instance.postgres.private_ip}:5432" }
output "db_instance_id" { value = aws_instance.postgres.id }