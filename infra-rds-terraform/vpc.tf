resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment
    Name = "main-${var.environment}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_default_security_group" "defaul" {
    vpc_id = aws_vpc.main.id
}
