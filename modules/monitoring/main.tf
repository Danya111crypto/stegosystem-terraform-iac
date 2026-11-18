variable "environment" { type = string }
variable "primary_app_id" { type = string }
variable "lb_instance_id" { type = string }
variable "db_instance_id" { type = string }

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-infrastructure-alerts"
}

resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
  alarm_name          = "${var.environment}-app-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Високе навантаження CPU вузла застосунку (>70%) — тригер масштабування"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.primary_app_id
  }
}

resource "aws_cloudwatch_metric_alarm" "lb_unhealthy" {
  alarm_name          = "${var.environment}-lb-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Збій перевірки стану балансувальника навантаження"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.lb_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_high_cpu" {
  alarm_name          = "${var.environment}-db-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Високе споживання CPU сервером бази даних PostgreSQL (>85%)"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.db_instance_id
  }
}

output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }