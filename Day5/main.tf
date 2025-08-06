###############################################################################
# Terraform とプロバイダー設定
###############################################################################
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1" # 東京
}

###############################################################################
# VPC
###############################################################################
resource "aws_vpc" "udemy_aws_14days" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "udemy-aws-14days-vpc"
  }
}

###############################################################################
# インターネットゲートウェイ
###############################################################################
resource "aws_internet_gateway" "udemy_aws_14days" {
  vpc_id = aws_vpc.udemy_aws_14days.id

  tags = {
    Name = "udemy-aws-14days-igw"
  }
}

###############################################################################
# パブリックサブネット（ap-northeast-1a）
###############################################################################
resource "aws_subnet" "udemy_aws_14days_public_1a" {
  vpc_id                  = aws_vpc.udemy_aws_14days.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "udemy-aws-14days-public-subnet-1a"
  }
}

###############################################################################
# プライベートサブネット（ap-northeast-1a）
###############################################################################
resource "aws_subnet" "udemy_aws_14days_private_1a" {
  vpc_id                  = aws_vpc.udemy_aws_14days.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "udemy-aws-14days-private-subnet-1a"
  }
}

###############################################################################
# パブリックサブネット（ap-northeast-1c）
###############################################################################
resource "aws_subnet" "udemy_aws_14days_public_1c" {
  vpc_id                  = aws_vpc.udemy_aws_14days.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "udemy-aws-14days-public-subnet-1c"
  }
}

###############################################################################
# プライベートサブネット（ap-northeast-1c）
###############################################################################
resource "aws_subnet" "udemy_aws_14days_private_1c" {
  vpc_id                  = aws_vpc.udemy_aws_14days.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "udemy-aws-14days-private-subnet-1c"
  }
}

###############################################################################
# パブリックルートテーブル
###############################################################################
resource "aws_route_table" "udemy_aws_14days_public" {
  vpc_id = aws_vpc.udemy_aws_14days.id

  tags = {
    Name = "udemy-aws-14days-public-subnet-route-table"
  }
}

# IGW ルート
resource "aws_route" "udemy_aws_14days_public_igw" {
  route_table_id         = aws_route_table.udemy_aws_14days_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.udemy_aws_14days.id
}

###############################################################################
# パブリックサブネットとルートテーブルの関連付け
###############################################################################
resource "aws_route_table_association" "udemy_aws_14days_public_1a" {
  subnet_id      = aws_subnet.udemy_aws_14days_public_1a.id
  route_table_id = aws_route_table.udemy_aws_14days_public.id
}

resource "aws_route_table_association" "udemy_aws_14days_public_1c" {
  subnet_id      = aws_subnet.udemy_aws_14days_public_1c.id
  route_table_id = aws_route_table.udemy_aws_14days_public.id
}

###############################################################################
# プライベートルートテーブル
###############################################################################
resource "aws_route_table" "udemy_aws_14days_private" {
  vpc_id = aws_vpc.udemy_aws_14days.id

  tags = {
    Name = "udemy-aws-14days-private-subnet-route-table"
  }
}

###############################################################################
# プライベートサブネットとルートテーブルの関連付け
###############################################################################
resource "aws_route_table_association" "udemy_aws_14days_private_1a" {
  subnet_id      = aws_subnet.udemy_aws_14days_private_1a.id
  route_table_id = aws_route_table.udemy_aws_14days_private.id
}

resource "aws_route_table_association" "udemy_aws_14days_private_1c" {
  subnet_id      = aws_subnet.udemy_aws_14days_private_1c.id
  route_table_id = aws_route_table.udemy_aws_14days_private.id
}

###############################################################################
# ──────────────────────── EC2 関連 ────────────────────────
###############################################################################

###############################################################################
# ──────────────────────── public-1a用インスタンス ────────────────────────
###############################################################################

# 1. AMI 取得
data "aws_ssm_parameter" "al2023_kernel61" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# 2. セキュリティグループ
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH (22), HTTP (80), HTTPS (443)"
  vpc_id      = aws_vpc.udemy_aws_14days.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# 3. EC2 インスタンス
resource "aws_instance" "web_1a" {
  ami                         = data.aws_ssm_parameter.al2023_kernel61.value
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.udemy_aws_14days_public_1a.id
  private_ip                  = "10.0.1.10"
  associate_public_ip_address = true
  key_name                    = "udemy-aws-14days"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-1a"
  }

    user_data = <<-EOF
#!/bin/bash

# ホスト名
hostnamectl set-hostname udemy-aws-14days-db-1a

# ロケールの変更
localectl set-locale LANG=ja_JP.UTF-8

# タイムゾーンの変更
timedatectl set-timezone Asia/Tokyo
  EOF

  user_data_replace_on_change = true
}

###############################################################################
# ──────────────────────── private-1a用インスタンス(DB用) ────────────────────────
###############################################################################

# 2. セキュリティグループ（web-sg からのみ許可）
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "DB inbound only from web-sg; egress all"
  vpc_id      = aws_vpc.udemy_aws_14days.id

  # 外向き通信を許可（NAT 無しのためインターネットへは出られません）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# SSH を web-sg からのみ許可
resource "aws_security_group_rule" "db_ssh_from_web" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.web_sg.id
}

# MySQL を web-sg からのみ許可
resource "aws_security_group_rule" "db_mysql_from_web" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.web_sg.id
}

# 3. EC2 インスタンス
resource "aws_instance" "db_1a" {
  ami           = data.aws_ssm_parameter.al2023_kernel61.value
  instance_type = "t2.micro"

  subnet_id     = aws_subnet.udemy_aws_14days_private_1a.id
  private_ip    = "10.0.101.20"
  associate_public_ip_address = false

  key_name               = "udemy-aws-14days"
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "db-1a"
  }

  user_data = <<-EOF
#!/bin/bash

# ホスト名
hostnamectl set-hostname udemy-aws-14days-db-1a

# ロケールの変更
localectl set-locale LANG=ja_JP.UTF-8

# タイムゾーンの変更
timedatectl set-timezone Asia/Tokyo
  EOF

  user_data_replace_on_change = true
}

###############################################################################
# RDS 用サブネットグループ
###############################################################################
resource "aws_db_subnet_group" "udemy_aws_14days_db" {
  name        = "udemy-aws-14days-db-subnet-group"
  description = "udemy-aws-14days-db-subnet-group"

  # プライベートサブネット（ap-northeast-1a / 1c）を指定
  subnet_ids = [
    aws_subnet.udemy_aws_14days_private_1a.id,
    aws_subnet.udemy_aws_14days_private_1c.id,
  ]

  # 明示的に VPC を紐づける属性は不要
  # AWS 側でサブネット → VPC を自動判定します
  tags = {
    Name = "udemy-aws-14days-db-subnet-group"
  }
}

###############################################################################
# RDS パラメータグループ（MySQL Community 8.4）
###############################################################################
resource "aws_db_parameter_group" "udemy_aws_14days_mysql84" {
  name        = "udemy-aws-14days-mysql84-parameter-group"
  description = "udemy-aws-14days-mysql84-parameter-group"
  family      = "mysql8.4"                # ← エンジンファミリー

  tags = {
    Name = "udemy-aws-14days-mysql84-parameter-group"
  }

  # slow query log をファイル出力で有効化
  parameter {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # しきい値（秒）。例：1 秒超を記録
  parameter {
    name         = "long_query_time"
    value        = "1"
    apply_method = "pending-reboot"
  }

  # 出力先を FILE に（TABLE でも可）
  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "pending-reboot"
  }
}

###############################################################################
# RDS: MySQL 8.4.5 (Multi-AZ インスタンスデプロイ)
###############################################################################
resource "aws_db_instance" "udemy_aws_14days_mysql" {
  ### 基本 ###
  identifier        = "udemy-aws-14days-mysql"
  engine            = "mysql"
  engine_version    = "8.4.5"            # MySQL 8.4 系
  instance_class = "db.t4g.micro"

  ### ストレージ ###
  allocated_storage = 20                # GB
  storage_type      = "gp3"

  ### 認証 ###
  username = "root"
  password = "Root!1234"                # 実運用では tfvars や Secrets Manager に分離推奨

  ### ネットワーク ###
  db_subnet_group_name   = aws_db_subnet_group.udemy_aws_14days_db.name   # private 1a/1c
  vpc_security_group_ids = [aws_security_group.db_sg.id]                  # inbound 制御

  # multi_az               = true        # 2 インスタンスでマルチ AZ

  publicly_accessible    = false       # IPv4 内部のみ
  # (デフォルトで IPv6 無効)

  ### パラメータグループ ###
  parameter_group_name = aws_db_parameter_group.udemy_aws_14days_mysql84.name

  ### バックアップ ###
  backup_retention_period = 2                # 日
  backup_window = "19:00-19:30"    # UTC

  ### メンテナンス ###
  maintenance_window = "sat:20:00-sat:20:30"

  ### その他オプション ###
  apply_immediately   = true            # 変更をすぐ反映（任意）
  skip_final_snapshot = true            # 破棄時スナップショット不要（検証環境向け）

  tags = {
    Name = "udemy-aws-14days-mysql"
  }
}


###############################################################################
# 出力
###############################################################################
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.udemy_aws_14days.id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.udemy_aws_14days.id
}

output "public_subnet_id_1a" {
  description = "ID of the public subnet (ap-northeast-1a)"
  value       = aws_subnet.udemy_aws_14days_public_1a.id
}

output "public_subnet_id_1c" {
  description = "ID of the public subnet (ap-northeast-1c)"
  value       = aws_subnet.udemy_aws_14days_public_1c.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.udemy_aws_14days_public.id
}

output "web_instance_id" {
  description = "ID of the EC2 instance (web-1a)"
  value       = aws_instance.web_1a.id
}
