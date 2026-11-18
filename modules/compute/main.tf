variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type" { type = string }
variable "min_size" {
  type    = number
  default = 2
}
variable "max_size" {
  type    = number
  default = 4
}
variable "desired_capacity" {
  type    = number
  default = 2
}

resource "aws_security_group" "elb" {
  name        = "${var.environment}-lb-sg"
  description = "Дозволяє HTTP/HTTPS трафік на балансувальник навантаження"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Дозволяє трафік до інстансів застосунку лише від балансувальника навантаження"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.elb.id]
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

resource "aws_instance" "lb" {
  ami                         = "ami-0c55b159cbfafe1f0"
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.elb.id]
  associate_public_ip_address = true

  user_data = base64encode("#!/bin/bash\necho 'Nginx Load Balancer -> App Cluster ${var.environment}' > /var/tmp/lb.conf")

  lifecycle {
    ignore_changes = [vpc_security_group_ids, instance_type]
  }

  tags = {
    Name = "${var.environment}-load-balancer"
    Role = "reverse-proxy-lb"
  }
}

resource "aws_eip" "lb" {
  instance = aws_instance.lb.id
  domain   = "vpc"

  tags = {
    Name = "${var.environment}-lb-eip"
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode("#!/bin/bash\necho 'StegoSystem App Ready' > /var/tmp/status.txt")
}

resource "aws_instance" "app" {
  count                  = var.desired_capacity
  ami                    = aws_launch_template.app.image_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = aws_launch_template.app.user_data

  lifecycle {
    ignore_changes = [vpc_security_group_ids, instance_type]
  }

  tags = {
    Name        = "${var.environment}-app-node-${count.index + 1}"
    ScalingPool = "${var.environment}-asg-pool (min:${var.min_size}/max:${var.max_size})"
  }
}

output "lb_endpoint" { value = "${aws_eip.lb.public_ip}:80" }
output "lb_instance_id" { value = aws_instance.lb.id }
output "app_instance_ids" { value = aws_instance.app[*].id }
output "asg_pool_info" { value = "${var.environment}-app-pool (${var.desired_capacity}/${var.max_size} nodes)" }
output "app_security_group_id" { value = aws_security_group.app.id }