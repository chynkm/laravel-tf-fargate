resource "aws_security_group" "ecs_elb" {
  name        = "${var.app_name}-elb-sg"
  description = "SG for ELB to access the ECS"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description      = "Allow HTTP access from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-elb-sg"
    Environment = "${var.app_env}"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-sg"
  description = "SG for ECS tasks to allow access only from the ELB"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description     = "Allow application access from ${var.app_name}-elb-sg"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_elb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-ecs-tasks-sg"
    Environment = "${var.app_env}"
  }
}

resource "aws_security_group" "ecs_cache" {
  name        = "${var.app_name}-ecs-cache-sg"
  description = "SG for Elasticache to allow access only from ECS"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description     = "Allow ECS access from ${var.app_name}-ecs-tasks-sg"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-ecs-cache-sg"
    Environment = "${var.app_env}"
  }
}

resource "aws_security_group" "ecs_rds" {
  name        = "${var.app_name}-rds-sg"
  description = "SG for RDS to allow access only from ECS"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description     = "Allow RDS access from ${var.app_name}-ecs-tasks-sg"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-rds-sg"
    Environment = var.app_env
  }
}
