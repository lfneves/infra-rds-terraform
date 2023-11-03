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

resource "aws_db_subnet_group" "subnet_group" {
  name        = "subnet-group"
  description = "DB subnet group"

  subnet_ids = var.subnet_group
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  name        = "rds-parameter-group"
  family      = "postgres15"
  description = "My DB Parameter Group"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
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
  vpc_security_group_ids          = var.security_group
  db_subnet_group_name            = aws_db_subnet_group.subnet_group.name
  parameter_group_name            = aws_db_parameter_group.rds_parameter_group.name
  storage_encrypted               = var.storage_encrypted
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.create_iam_role ? aws_iam_role.enhanced_monitoring[0].arn : ""
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports
  publicly_accessible             = true

  tags = merge(
    {
      Name        = "DatabaseServer",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "null_resource" "create_table" {
  triggers = {
      instance_id = aws_db_instance.postgresql.id
  }

  provisioner "local-exec" {
    command = "psql -h ${element(split(":", aws_db_instance.postgresql.endpoint), 0)} -p 5432 -U ${aws_db_instance.postgresql.username} -d ${aws_db_instance.postgresql.identifier} -a -f table_schema.sql"
  }
}

