locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Module      = "rds"
    ManagedBy   = "terraform"
  })

  db_port = var.port != null ? var.port : (var.engine == "postgres" ? 5432 : 3306)

  parameter_group_family = var.engine == "postgres" ? "postgres${split(".", var.engine_version)[0]}" : "mysql${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}"

  aurora_cluster_family = var.engine == "postgres" ? "aurora-postgresql${split(".", var.engine_version)[0]}" : "aurora-mysql${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}"

  aurora_engine = var.engine == "postgres" ? "aurora-postgresql" : "aurora-mysql"
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for ${var.use_aurora ? "Aurora" : "RDS"} database"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_security_group_ids) > 0 ? [1] : []
    content {
      from_port       = local.db_port
      to_port         = local.db_port
      protocol        = "tcp"
      security_groups = var.allowed_security_group_ids
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = local.db_port
      to_port     = local.db_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
  })
}

resource "aws_db_parameter_group" "main" {
  count  = var.use_aurora ? 0 : 1
  name   = "${var.project_name}-${var.environment}-db-params"
  family = local.parameter_group_family
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  count  = var.use_aurora ? 1 : 0
  name   = "${var.project_name}-${var.environment}-aurora-cluster-params"
  family = local.aurora_cluster_family
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-cluster-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora_instance" {
  count  = var.use_aurora ? 1 : 0
  name   = "${var.project_name}-${var.environment}-aurora-instance-params"
  family = local.parameter_group_family
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-instance-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "master" {
  count   = var.master_password == null ? 1 : 0
  length  = 16
  special = true
  
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_kms_key" "db" {
  count                   = var.storage_encrypted ? 1 : 0
  description             = "KMS key for ${var.project_name}-${var.environment} database encryption"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-kms-key"
  })
}

resource "aws_kms_alias" "db" {
  count         = var.storage_encrypted ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-db-key"
  target_key_id = aws_kms_key.db[0].key_id
}