# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Security groups
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# SSM
resource "aws_security_group" "ssm_vpce" {
  count = var.create_operational_baseline && var.create_ssm_vpc_endpoint ? 1 : 0

  name        = "${var.prefix}-ssm-vpc-endpoints"
  description = "Allow HTTPS from private subnets to SSM interface endpoints"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this[0].cidr_block]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-ssm-vpc-endpoints" })
}

# ALB
resource "aws_security_group" "alb" {
  count = var.create_operational_baseline ? 1 : 0

  name   = "${var.prefix}-alb"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.lb_ingress_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.lb_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-alb" })
}

# NLB
resource "aws_security_group" "nlb" {
  count = var.create_operational_baseline ? 1 : 0

  name   = "${var.prefix}-nlb"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.lb_ingress_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.lb_ingress_cidr_blocks
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.lb_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-nlb" })
}

# Zabbix
resource "aws_security_group" "zabbix" {
  count = var.create_operational_baseline ? 1 : 0

  vpc_id = local.vpc_id
  name   = "${var.prefix}-zabbix"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = var.zabbix_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = var.zabbix_cidr_blocks
  }

  ingress {
    from_port   = 10050
    to_port     = 10050
    protocol    = "TCP"
    cidr_blocks = concat(var.zabbix_cidr_blocks)
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = var.zabbix_cidr_blocks
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { "Name" = "${var.prefix}-zabbix" })
}


# Gitlab
resource "aws_security_group" "gitlab" {
  count = var.create_operational_baseline ? 1 : 0

  name   = "${var.prefix}-gitlab"
  vpc_id = local.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id, aws_security_group.nlb[0].id]
    description     = "Allow HTTP from LB"
  }

  ingress {
    from_port       = 5050
    to_port         = 5050
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id, aws_security_group.nlb[0].id]
    description     = "Allow gitlab container registry from LB"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb[0].id]
    description     = "Allow SSH from NLB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-gitlab" })
}


# Sonarqube
resource "aws_security_group" "sonarqube" {
  count = var.create_operational_baseline ? 1 : 0

  name   = "${var.prefix}-sonarqube"
  vpc_id = local.vpc_id

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
    description     = "Allow Sonarqube from ALB"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-sonarqube" })
}


# Artifactory
resource "aws_security_group" "artifactory" {
  count = var.create_operational_baseline ? 1 : 0

  name   = "${var.prefix}-artifactory"
  vpc_id = local.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb[0].id]
    description     = "Allow HTTP from ALB"
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "TCP"
    cidr_blocks = [data.aws_vpc.this[0].cidr_block]
    description = "Allow Xray from local"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-artifactory" })
}
