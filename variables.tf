variable "aws_region" {
  description = "Регіон розгортання інфраструктури"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Назва проєкту для тегування ресурсів"
  type        = string
  default     = "stegosystem-cloud"
}

variable "vpc_cidr" {
  description = "CIDR блок віртуальної мережі VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Зони доступності для високої відмовостійкості"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "Тип обчислювальних інстансів"
  type        = string
  default     = "t3.micro"
}

variable "active_slot" {
  description = "Активний слот розгортання для стратегії Blue/Green (blue або green)"
  type        = string
  default     = "blue"
}