resource "aws_elasticache_subnet_group" "ecs_cache_subnet_group" {
  name       = "${var.app_name}-subnet-group"
  subnet_ids = aws_subnet.ecs_public.*.id

  tags = {
    Name        = "${var.app_name}-redis"
    Environment = var.app_env
  }
}

resource "aws_elasticache_replication_group" "ecs_cache_replication_group" {
  replication_group_id       = "${var.app_name}-replication-group"
  description                = "Elasticache for ${var.app_name}"
  engine                     = "redis"
  engine_version             = "6.2"
  node_type                  = "cache.t4g.micro"
  port                       = 6379
  automatic_failover_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.ecs_cache_subnet_group.name
  security_group_ids         = [aws_security_group.ecs_cache.id]

  replicas_per_node_group = 3
  num_node_groups         = 1

  tags = {
    Name        = "${var.app_name}-redis"
    Environment = "${var.app_env}"
  }
}
