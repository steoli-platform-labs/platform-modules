# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# RDS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
resource "aws_db_subnet_group" "this" {
  name       = "${var.prefix}-${var.stack_name}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, { Name = "${var.prefix}-subnets" })
}

resource "aws_security_group" "db" {
  name   = "${var.prefix}-${var.stack_name}-db"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "Allow Postgres from app SGs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-db" })
}

resource "random_password" "master" {
  count   = trimspace(var.password) == "" ? 1 : 0
  length  = 24
  special = true

  # Avoid characters that often cause tooling/URL escaping issues
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  password = trimspace(var.password) != "" ? var.password : random_password.master[0].result
}

resource "aws_db_instance" "this" {
  identifier     = "${var.prefix}-${var.stack_name}"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type

  username = var.username
  password = local.password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  multi_az = var.multi_az

  storage_encrypted           = true
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  apply_immediately           = var.apply_immediately
  allow_major_version_upgrade = var.allow_major_version_upgrade

  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  backup_retention_period = var.backup_retention_period
  copy_tags_to_snapshot   = true

  # Enable storage autoscaling if max_allocated_storage > 0
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null

  tags = merge(var.common_tags, { Name = "${var.prefix}-${var.stack_name}" })
}
