resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-${var.app_env}-cluster"

  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.app_env
  }
}

locals {
  env_vars = [
    {
      "name" : "APP_ENV",
      "value" : "production"
    },
    {
      "name" : "APP_KEY",
      "value" : "base64:jiuup8dpsFJDH/VW1xwJGzvcdY2eVNhg358fuB4JFgA="
    },
    {
      "name" : "APP_NAME",
      "value" : "LiteBreeze Laravel ECS example"
    },
    {
      "name" : "APP_DEBUG",
      "value" : "false"
    },
    {
      "name" : "APP_URL",
      "value" : "${aws_alb.ecs_alb.dns_name}"
    },
    {
      "name" : "BROADCAST_DRIVER",
      "value" : "log"
    },
    {
      "name" : "CACHE_DRIVER",
      "value" : "redis"
    },
    {
      "name" : "FILESYSTEM_DISK",
      "value" : "s3"
    },
    {
      "name" : "QUEUE_CONNECTION",
      "value" : "redis"
    },
    {
      "name" : "SESSION_DRIVER",
      "value" : "redis"
    },
    {
      "name" : "SESSION_LIFETIME",
      "value" : "120"
    },
    {
      "name" : "LOG_CHANNEL",
      "value" : "stderr"
    },
    {
      "name" : "LOG_LEVEL",
      "value" : "error"
    },
    {
      "name" : "AWS_DEFAULT_REGION",
      "value" : "${var.aws_region}"
    },
    {
      "name" : "AWS_BUCKET",
      "value" : "${aws_s3_bucket.ecs_s3.bucket}"
    },
    {
      "name" : "REDIS_CLUSTER_ENABLED",
      "value" : "true"
    },
    {
      "name" : "REDIS_HOST",
      "value" : "${aws_elasticache_replication_group.ecs_cache_replication_group.primary_endpoint_address}"
    },
    {
      "name" : "REDIS_CLIENT",
      "value" : "phpredis"
    },
    {
      "name" : "DB_CONNECTION",
      "value" : "mysql"
    },
    {
      "name" : "DB_HOST",
      "value" : "${aws_db_instance.ecs_rds.address}"
    },
    {
      "name" : "DB_PORT",
      "value" : "3306"
    },
    {
      "name" : "DB_DATABASE",
      "value" : "${aws_db_instance.ecs_rds.db_name}"
    },
    {
      "name" : "DB_USERNAME",
      "value" : "${aws_db_instance.ecs_rds.username}"
    },
    {
      "name" : "DB_PASSWORD",
      "value" : "${random_password.db_generated_password.result}"
    }
  ]

  container_worker_role = [
    {
      "name" : "CONTAINER_ROLE",
      "value" : "worker"
    }
  ]

  container_scheduler_role = [
    {
      "name" : "CONTAINER_ROLE",
      "value" : "scheduler"
    }
  ]
}

resource "aws_ecs_task_definition" "ecs_task_webserver" {
  container_definitions = <<DEFINITION
  [
    {
      "name": "nginx",
      "image": "chynkm/nginx-ecs:latest",
      "essential": true,
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "${aws_cloudwatch_log_group.ecs_webserver_logs.id}",
              "awslogs-region": "${var.aws_region}",
              "awslogs-stream-prefix": "${var.app_name}-${var.app_env}-nginx"
          }
      },
      "portMappings": [{
        "containerPort": 80,
        "hostPort": 80
      }],
      "dependsOn": [{
        "containerName": "php",
        "condition": "HEALTHY"
      }],
      "volumesFrom": [{
        "sourceContainer": "php",
        "readOnly": true
      }],
      "healthCheck": {
        "command": [
            "CMD-SHELL",
            "curl -f http://localhost/health_check || exit 1"
        ],
        "interval": 5,
        "timeout": 2,
        "retries": 3
      },
      "memory": 256,
      "cpu": 256
    },
    {
      "name": "php",
      "image": "chynkm/laravel-ecs:latest",
      "essential": true,
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "${aws_cloudwatch_log_group.ecs_webserver_logs.id}",
              "awslogs-region": "${var.aws_region}",
              "awslogs-stream-prefix": "${var.app_name}-${var.app_env}-php"
          }
      },
      "environment": ${jsonencode(local.env_vars)},
      "portMappings": [{
    	  "containerPort": 9000
      }],
      "volumes": [{
          "name": "webroot"
      }],
      "healthCheck": {
          "command": [
          "CMD-SHELL",
          "nc -z -v 127.0.0.1 9000 || exit 1"
          ],
          "interval": 5,
          "timeout": 2,
          "retries": 3
      },
      "memory": 768,
      "cpu": 256
    }
  ]
  DEFINITION

  family                   = "${var.app_name}-${var.app_env}-webserver-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "1024"
  cpu                      = "512"
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_execution_role.arn

  tags = {
    Name        = "${var.app_name}-ecs-webserver-task"
    Environment = var.app_env
  }
}

resource "aws_ecs_service" "ecs_service_webserver" {
  name                   = "${var.app_name}-${var.app_env}-ecs-webserver-service"
  cluster                = aws_ecs_cluster.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.ecs_task_webserver.arn
  launch_type            = "FARGATE"
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.ecs_public.*.id
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.ecs_alb_http_listener]

  tags = {
    Name        = "${var.app_name}-ecs-webserver-service"
    Environment = var.app_env
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service_webserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_scale_up" {
  name               = "${var.app_name}-${var.app_env}-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_scale_down" {
  name               = "${var.app_name}-${var.app_env}-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_policy_cpu_high" {
  alarm_name          = "${var.app_name}-${var.app_env}-cpu-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service_webserver.name
  }

  alarm_description = "This metric monitors ECS ${var.app_name} CPU high utilization"
  alarm_actions     = [aws_appautoscaling_policy.ecs_policy_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_policy_cpu_low" {
  alarm_name          = "${var.app_name}-${var.app_env}-cpu-scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service_webserver.name
  }

  alarm_description = "This metric monitors ECS ${var.app_name} CPU low utilization"
  alarm_actions     = [aws_appautoscaling_policy.ecs_policy_scale_down.arn]
}


resource "aws_ecs_task_definition" "ecs_task_worker" {
  container_definitions = <<DEFINITION
  [
    {
      "name": "php",
      "image": "chynkm/laravel-ecs:latest",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.ecs_worker_logs.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_env}-php"
        }
      },
      "environment": ${jsonencode(concat(local.env_vars, local.container_worker_role))},
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "ps aux | grep -v grep | grep -c 'queue:work' || exit 1"
        ],
        "interval": 5,
        "timeout": 2,
        "retries": 3
      },
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION

  family                   = "${var.app_name}-${var.app_env}-worker-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_execution_role.arn

  tags = {
    Name        = "${var.app_name}-ecs-worker-task"
    Environment = var.app_env
  }
}

resource "aws_ecs_service" "ecs_service_worker" {
  name                   = "${var.app_name}-${var.app_env}-ecs-worker-service"
  cluster                = aws_ecs_cluster.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.ecs_task_worker.arn
  launch_type            = "FARGATE"
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.ecs_public.*.id
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_tasks.id]
  }

  depends_on = [aws_ecs_service.ecs_service_webserver]

  tags = {
    Name        = "${var.app_name}-ecs-worker-service"
    Environment = var.app_env
  }
}

resource "aws_ecs_task_definition" "ecs_task_scheduler" {
  container_definitions = <<DEFINITION
  [
    {
      "name": "php",
      "image": "chynkm/laravel-ecs:latest",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.ecs_scheduler_logs.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_env}-php"
        }
      },
      "environment": ${jsonencode(concat(local.env_vars, local.container_scheduler_role))},
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION

  family                   = "${var.app_name}-${var.app_env}-scheduler-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_tasks_execution_role.arn

  tags = {
    Name        = "${var.app_name}-ecs-scheduler-task"
    Environment = var.app_env
  }
}

resource "aws_ecs_service" "ecs_service_scheduler" {
  name                   = "${var.app_name}-${var.app_env}-ecs-scheduler-service"
  cluster                = aws_ecs_cluster.ecs_cluster.id
  task_definition        = aws_ecs_task_definition.ecs_task_scheduler.arn
  launch_type            = "FARGATE"
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.ecs_public.*.id
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_tasks.id]
  }

  depends_on = [aws_ecs_service.ecs_service_webserver]

  tags = {
    Name        = "${var.app_name}-ecs-scheduler-service"
    Environment = var.app_env
  }
}
