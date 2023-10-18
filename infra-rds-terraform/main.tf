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

# resource "aws_iam_role" "enhanced_monitoring" {
#   name               = "rds-${var.environment}-role"
#   assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring.json
# }

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#
# Security group resources
#
resource "aws_security_group" "postgresql" {
  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "sgDatabaseServer",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

#
# RDS resources
#
resource "aws_db_parameter_group" "delivery" {
  name   = "delivery"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}


resource "aws_db_option_group_option" "disable_ssl" {
  name = "disable_ssl"
  option_name       = "rds.force_ssl"
  option_settings   = [
    {
      name  = "rds.force_ssl"
      value = "0"
    }
  ]
}


resource "aws_db_instance" "postgresql" {
  allocated_storage               = var.allocated_storage
  engine                          = "postgres"
  engine_version                  = var.engine_version
  identifier                      = var.database_identifier
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
  vpc_security_group_ids          = [aws_security_group.postgresql.id]
  db_subnet_group_name            = var.subnet_group
  parameter_group_name            = var.parameter_group
  storage_encrypted               = var.storage_encrypted
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring.arn : ""
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports
  option_group_name               = aws_db_option_group_option.name

  tags = merge(
    {
      Name        = "DatabaseServer",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}
