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
