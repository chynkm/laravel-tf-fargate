resource "aws_db_subnet_group" "ecs_rds_subnet_group" {
  name       = "${var.app_name}-rds-subnet-group"
  subnet_ids = aws_subnet.ecs_public.*.id

  tags = {
    Name        = "${var.app_name}-rds"
    Environment = var.app_env
  }
}

resource "aws_db_instance" "ecs_rds" {
  allocated_storage           = 10
  engine                      = "mysql"
  engine_version              = "8.0.23"
  instance_class              = "db.t2.micro"
  identifier                  = "${var.app_name}-mysql"
  db_name                     = "litebreezeStaging"
  username                    = "root"
  password                    = random_password.db_generated_password.result
  parameter_group_name        = "default.mysql8.0"
  multi_az                    = false
  publicly_accessible         = true
  skip_final_snapshot         = true
  storage_type                = "gp2"
  backup_window               = "00:00-00:30"
  backup_retention_period     = 7
  maintenance_window          = "Mon:00:30-Mon:01:00"
  allow_major_version_upgrade = false
  vpc_security_group_ids      = [aws_security_group.ecs_rds.id]
  db_subnet_group_name        = aws_db_subnet_group.ecs_rds_subnet_group.name

  tags = {
    Name        = "${var.app_name}-rds"
    Environment = var.app_env
  }
}
