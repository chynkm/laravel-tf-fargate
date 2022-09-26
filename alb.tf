resource "aws_alb" "ecs_alb" {
  name               = "${var.app_name}-application-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_elb.id]
  subnets            = aws_subnet.ecs_public.*.id

  tags = {
    Name        = "${var.app_name}-application-elb"
    Environment = "${var.app_env}"
  }
}

resource "aws_lb_target_group" "ecs_alb_tg" {
  name        = "${var.app_name}-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/health_check"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.app_name}-alb-tg"
    Environment = "${var.app_env}"
  }
}

resource "aws_lb_listener" "ecs_alb_http_listener" {
  load_balancer_arn = aws_alb.ecs_alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_alb_tg.id
  }

  tags = {
    Name        = "${var.app_name}-http-listener"
    Environment = "${var.app_env}"
  }
}
