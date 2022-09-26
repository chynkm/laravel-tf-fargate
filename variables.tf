variable "app_name" {
  type    = string
  default = "litebreeze-ecs"
}

variable "app_env" {
  type    = string
  default = "staging"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the infrastructure will be created"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "IP address range to use in VPC"
  default     = "172.16.0.0/16"
}

variable "az_count" {
  description = "Number of Availability zones"
  default     = "3"
}

variable "subnet_count" {
  description = "Number of subnets"
  default     = "3"
}
