resource "aws_cloudwatch_log_group" "ecs_webserver_logs" {
  name              = "${var.app_name}-${var.app_env}-webserver-logs"
  retention_in_days = 3

  tags = {
    Name        = "${var.app_name}-webserver-logs"
    Environment = var.app_env
  }
}

resource "aws_cloudwatch_log_group" "ecs_worker_logs" {
  name              = "${var.app_name}-${var.app_env}-worker-logs"
  retention_in_days = 3

  tags = {
    Name        = "${var.app_name}-worker-logs"
    Environment = var.app_env
  }
}

resource "aws_cloudwatch_log_group" "ecs_scheduler_logs" {
  name              = "${var.app_name}-${var.app_env}-scheduler-logs"
  retention_in_days = 3

  tags = {
    Name        = "${var.app_name}-scheduler-logs"
    Environment = var.app_env
  }
}
