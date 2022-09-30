resource "random_password" "db_generated_password" {
  length           = 16
  special          = true
  override_special = "*-_"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.app_name}/${var.app_env}/database/password/master"
  description = "MySQL master password"
  type        = "SecureString"
  value       = random_password.db_generated_password.result

  tags = {
    Name        = "${var.app_name}-application-elb"
    Environment = "${var.app_env}"
  }
}
