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

#
# 1. AMI 取得
#    指定バージョン (2023.8.20250721.2 kernel-6.1) をフィルタ。
#    将来バージョン固定を変える場合は filter を修正してください。
#
data "aws_ssm_parameter" "al2023_kernel61" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

#
# 2. セキュリティグループ
#
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

#
# 3. EC2 インスタンス
#
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
}

###############################################################################
# ──────────────────────── private-1a用インスタンス(DB用) ────────────────────────
###############################################################################

#
# 2. セキュリティグループ（web-sg からのみ許可）
#
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "DB inbound only from web-sg; egress all"
  vpc_id      = aws_vpc.udemy_aws_14days.id

  # 外向き通信を許可
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

#
# 3. EC2 インスタンス
#
resource "aws_instance" "db_1a" {
  ami           = data.aws_ssm_parameter.al2023_kernel61.value
  instance_type = "t2.micro"

  subnet_id     = aws_subnet.udemy_aws_14days_private_1a.id
  private_ip    = "10.0.101.20"                # ← プライベートサブネット内のIPに修正
  associate_public_ip_address = false          # ← プライベートサブネットなので付けない

  key_name                 = "udemy-aws-14days"
  vpc_security_group_ids   = [aws_security_group.db_sg.id]  # ← db_sg を付ける

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
# NAT Gateway（public-1a） + Elastic IP
###############################################################################

# NAT 用 Elastic IP
resource "aws_eip" "nat_1a" {
  domain = "vpc"
  tags = {
    Name = "udemy-aws-14days-nat-eip-1a"
  }
}

# NAT Gateway（public-1a サブネットに配置）
resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.udemy_aws_14days_public_1a.id
  tags = {
    Name = "udemy-aws-14days-nat-1a"
  }
  # 先に IGW が付いている必要があるため依存関係を明示
  depends_on = [aws_internet_gateway.udemy_aws_14days]
}

###############################################################################
# Private ルートテーブルにデフォルトルートを追加（0.0.0.0/0 → NAT）
###############################################################################
resource "aws_route" "private_default_to_nat" {
  route_table_id         = aws_route_table.udemy_aws_14days_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
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

output "nat_gateway_id_1a" {
  value       = aws_nat_gateway.nat_1a.id
  description = "NAT Gateway in public-1a"
}
output "nat_eip_public_ip_1a" {
  value       = aws_eip.nat_1a.public_ip
  description = "Elastic IP attached to NAT in public-1a"
}