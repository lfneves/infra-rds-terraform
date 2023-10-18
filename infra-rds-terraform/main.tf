#
# IAM resources
#
data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.create_iam_role ? 1 : 0  # Use a variable to conditionally create the role

  name = "rds-delivery-role"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# #
# # Security group resources
# #
# resource "aws_security_group" "postgresql" {
#   vpc_id = var.vpc_id

#   tags = merge(
#     {
#       Name        = "sgDatabaseServer",
#       Project     = var.project,
#       Environment = var.environment
#     },
#     var.tags
#   )
# }

# #
# # RDS resources
# #
# resource "aws_db_parameter_group" "delivery" {
#   name   = "delivery"
#   family = "postgres15"

#   parameter {
#     name  = "log_connections"
#     value = "1"
#   }
# }

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

resource "aws_default_security_group" "default" {
    vpc_id = aws_vpc.main.id
}


# RDS DB SECURITY GROUP
resource "aws_security_group" "sg" {
  name        = "postgresql-delivery"
  description = "Allow EKS inbound/outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-1"].cidr_block]  
  }

  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-2"].cidr_block]  
  }
  
  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-1"].cidr_block]  
  }

  ingress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-2"].cidr_block]  
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-1"].cidr_block]  
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private["private-rds-2"].cidr_block]  
  }

  egress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-1"].cidr_block]  
  }

  egress {
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.public["public-rds-2"].cidr_block]  
  }

  tags = {
    Name        = "postgresql-${var.environment}"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = all
  }
}

# RDS DB SUBNET GROUP
resource "aws_db_subnet_group" "sg" {
  name       = "postgresql-${var.environment}"
  subnet_ids = [aws_subnet.private["private-rds-1"].id, aws_subnet.private["private-rds-2"].id]

  tags = {
    Environment = var.environment
    Name        = "postgresql-${var.environment}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# RDS instance
resource "aws_db_instance" "postgresql" {
  allocated_storage               = var.allocated_storage
  engine                          = "postgres"
  db_name                         = "postgresdb"
  engine_version                  = var.engine_version
  identifier                      = "postgresql-${var.environment}"
  snapshot_identifier             = var.snapshot_identifier
  instance_class                  = var.instance_type
  storage_type                    = var.storage_type
  iops                            = var.iops
  password                        = var.database_password
  username                        = var.database_username
  backup_retention_period         = var.backup_retention_period
  backup_window                   = var.backup_window
  maintenance_window              = var.maintenance_window
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  final_snapshot_identifier       = var.final_snapshot_identifier
  skip_final_snapshot             = var.skip_final_snapshot
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  multi_az                        = var.multi_availability_zone
  port                            = var.database_port
  vpc_security_group_ids          = [aws_security_group.sg.id]
  db_subnet_group_name            = aws_db_subnet_group.sg.id
  parameter_group_name            = var.parameter_group
  storage_encrypted               = var.storage_encrypted
  monitoring_interval             = var.create_iam_role ? aws_iam_role.enhanced_monitoring[0].arn : ""
  monitoring_role_arn             = local.monitoring_role_arn
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports

  tags = merge(
    {
      Name        = "DatabaseServer",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

# RDS subnet
resource "aws_subnet" "private" {
  for_each = {
    for subnet in local.private_nested_config : "${subnet.name}" => subnet
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Environment = var.environment
    Name        = "${each.value.name}-${var.environment}"
    "kubernetes.io/role/internal-elb" = each.value.eks ? "1" : ""
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "public" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Environment = var.environment
    Name        = "${each.value.name}-${var.environment}"
    "kubernetes.io/role/elb" = each.value.eks ? "1" : ""
  }

  lifecycle {
    ignore_changes = all
  }
}
