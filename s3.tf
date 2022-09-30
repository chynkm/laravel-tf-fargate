resource "aws_s3_bucket" "ecs_s3" {
  bucket = "${var.app_name}-${var.app_env}-assets"
}

resource "aws_s3_bucket_acl" "ecs_s3_acl" {
  bucket = aws_s3_bucket.ecs_s3.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "ecs_s3_permissions" {
  bucket = aws_s3_bucket.ecs_s3.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}
