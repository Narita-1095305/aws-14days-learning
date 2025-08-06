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
    security_groups = [aws_security_group.alb_sg.id]
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
    set -eux

    ##########################################################################
    # 基本設定
    ##########################################################################
    # ホスト名
    hostnamectl set-hostname udemy-aws-14days-web-1a

    # ロケール & タイムゾーン
    localectl set-locale LANG=ja_JP.UTF-8
    timedatectl set-timezone Asia/Tokyo

    ##########################################################################
    # パッケージ更新 & Apache / PHP / Git
    ##########################################################################
    dnf -y update
    dnf -y install httpd php8.4 git

    ##########################################################################
    # MySQL クライアント & PHP MySQL 拡張
    ##########################################################################
    dnf -y install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
    dnf -y install mysql php-mysqlnd

    ##########################################################################
    # Apache 設定変更
    ##########################################################################
    # DirectoryIndex を index.php 優先に
    sed -i 's#^<IfModule dir_module>.*#<IfModule dir_module>\\n    DirectoryIndex index.php index.html\\n</IfModule>#' /etc/httpd/conf/httpd.conf
    # ServerName を設定
    echo 'ServerName udemy-aws-14days-web-1a' >> /etc/httpd/conf/httpd.conf

    # 設定テスト & Apache 起動
    httpd -t
    systemctl enable httpd
    systemctl restart httpd

    ##########################################################################
    # アプリ配置
    ##########################################################################
    cd /tmp
    git clone https://github.com/ketancho/udemy-aws-14days.git
    cp -r udemy-aws-14days/Day04/* /var/www/html/
    chown -R apache:apache /var/www/html

    ##########################################################################
    # index.php の DB 接続先を書き換え（10.0.101.20 → RDS エンドポイント）
    ##########################################################################
    sed -i -E "s#mysql:host=[^;]+;#mysql:host=${aws_db_instance.udemy_aws_14days_mysql.address};#g" \
    /var/www/html/index.php

  EOF

  # 変更があったらインスタンス再作成せず user_data だけ再適用
  user_data_replace_on_change = true
}

###############################################################################
# ──────────────────────── public-1c 用インスタンス ────────────────────────
###############################################################################
resource "aws_instance" "web_1c" {
  ami           = data.aws_ssm_parameter.al2023_kernel61.value
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.udemy_aws_14days_public_1c.id  # ← 1c
  private_ip                  = "10.0.2.10"                               # ← 1c サブネット内で重複しない IP
  associate_public_ip_address = true
  key_name                    = "udemy-aws-14days"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-1c"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    ##########################################################################
    # 基本設定
    ##########################################################################
    hostnamectl set-hostname udemy-aws-14days-web-1c
    localectl set-locale LANG=ja_JP.UTF-8
    timedatectl set-timezone Asia/Tokyo

    ##########################################################################
    # パッケージ更新 & Apache / PHP / Git
    ##########################################################################
    dnf -y update
    dnf -y install httpd php8.4 git

    ##########################################################################
    # MySQL クライアント & PHP MySQL 拡張
    ##########################################################################
    dnf -y install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
    dnf -y install mysql php-mysqlnd

    ##########################################################################
    # Apache 設定変更
    ##########################################################################
    sed -i 's#^<IfModule dir_module>.*#<IfModule dir_module>\\n    DirectoryIndex index.php index.html\\n</IfModule>#' /etc/httpd/conf/httpd.conf
    echo 'ServerName udemy-aws-14days-web-1c' >> /etc/httpd/conf/httpd.conf

    httpd -t
    systemctl enable httpd
    systemctl restart httpd

    ##########################################################################
    # アプリ配置
    ##########################################################################
    cd /tmp
    git clone https://github.com/ketancho/udemy-aws-14days.git
    cp -r udemy-aws-14days/Day04/* /var/www/html/
    chown -R apache:apache /var/www/html

    ##########################################################################
    # index.php の DB 接続先を書き換え（10.0.101.20 → RDS エンドポイント）
    ##########################################################################
    sed -i -E "s#mysql:host=[^;]+;#mysql:host=${aws_db_instance.udemy_aws_14days_mysql.address};#g" \
    /var/www/html/index.php

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

# # 3. EC2 インスタンス
# resource "aws_instance" "db_1a" {
#   ami           = data.aws_ssm_parameter.al2023_kernel61.value
#   instance_type = "t2.micro"

#   subnet_id     = aws_subnet.udemy_aws_14days_private_1a.id
#   private_ip    = "10.0.101.20"
#   associate_public_ip_address = false

#   key_name               = "udemy-aws-14days"
#   vpc_security_group_ids = [aws_security_group.db_sg.id]

#   tags = {
#     Name = "db-1a"
#   }

#   user_data = <<-EOF
# #!/bin/bash

# # ホスト名
# hostnamectl set-hostname udemy-aws-14days-db-1a

# # ロケールの変更
# localectl set-locale LANG=ja_JP.UTF-8

# # タイムゾーンの変更
# timedatectl set-timezone Asia/Tokyo
#   EOF

#   user_data_replace_on_change = true
# }

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
# ──────────────────────── ALB 用セキュリティグループ ────────────────────────
###############################################################################
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "alb-sg"
  vpc_id      = aws_vpc.udemy_aws_14days.id

  # ────────────── インバウンド ──────────────
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ────────────── アウトバウンド ──────────────
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

###############################################################################
# ──────────────────────── Application Load Balancer ────────────────────────
###############################################################################
resource "aws_lb" "udemy_aws_14days_alb" {
  name               = "udemy-aws-14days-alb"
  load_balancer_type = "application"
  internal           = false                 # インターネット向け
  ip_address_type    = "ipv4"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.udemy_aws_14days_public_1a.id,   # AZ: ap-northeast-1a
    aws_subnet.udemy_aws_14days_public_1c.id,   # AZ: ap-northeast-1c
  ]

  tags = {
    Name = "udemy-aws-14days-alb"
  }
}

###############################################################################
# ──────────────────────── HTTP リスナー (port 80) ────────────────────────────
###############################################################################
resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.udemy_aws_14days_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.udemy_aws_14days_tg.arn
  }
}


###############################################################################
# ──────────────────────── RDS 初期化 ────────────────────────
###############################################################################
resource "null_resource" "init_rds" {
  # RDS と Web EC2 が完成してから実行する
  depends_on = [
    aws_db_instance.udemy_aws_14days_mysql,
    aws_instance.web_1a
  ]

  # エンドポイントが変わったら再実行
  triggers = {
    rds_endpoint = aws_db_instance.udemy_aws_14days_mysql.endpoint
  }

  provisioner "remote-exec" {
    inline = [
      # RDS が完全起動するまで少し待機（30 秒 × 10 = 最大 5 分）
      "for i in {1..10}; do mysqladmin ping -h ${aws_db_instance.udemy_aws_14days_mysql.address} -u root -p'Root!1234' && break || sleep 30; done",

      # まとめて SQL 投入
      # ↓↓↓ ここから SQL を修正 ↓↓↓
      "mysql -h ${aws_db_instance.udemy_aws_14days_mysql.address} -u root -p'Root!1234' <<'EOSQL'",
      "CREATE DATABASE IF NOT EXISTS simple_blog;",
      "CREATE USER IF NOT EXISTS 'simple_blog_user'@'%' IDENTIFIED BY 'User!1234';",
      "GRANT ALL PRIVILEGES ON simple_blog.* TO 'simple_blog_user'@'%';",
      "FLUSH PRIVILEGES;",
      "USE simple_blog;",
      "CREATE TABLE IF NOT EXISTS posts (",
      "  id INT NOT NULL PRIMARY KEY,",
      "  title  VARCHAR(100),",
      "  detail VARCHAR(1000),",
      "  image  VARCHAR(1000)",
      ");",
      "INSERT INTO posts VALUES",
      "  (1, '[RDS] JAWS Days 初参加（2014）',  '学びが多かった。何より熱量に驚いた。自分も発信する側になりたい。', './img/img1.png'),",
      "  (2, '[RDS] re:Invent 初参加（2016）', '規模の大きさに驚いた。個人的には Step Functions の発表が1番よかった。', './img/img2.png'),",
      "  (3, '[RDS] AWS 設計 に関する本を執筆しました（2018）', '多くの方に読んでいただけたら嬉しいです。', './img/img3.png'),",
      "  (4, '[RDS] AWS SAA 資格対策の本を執筆しました（2019）', 'オリジナル問題を通して対策していただけます。', './img/img4.png');",
      "EOSQL"
      # ↑↑↑ ここまで ↑↑↑
    ]

    # Web EC2 へ SSH 接続する情報
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.web_1a.public_ip        # ※ Elastic IP を付与しているならそちらでも可
      private_key = file("./udemy-aws-14days.pem")        # キーペアの秘密鍵パスを合わせてね
    }
  }
}

###############################################################################
# ──────────────────────── ALB ターゲットグループ ────────────────────────
###############################################################################
resource "aws_lb_target_group" "udemy_aws_14days_tg" {
  name             = "udemy-aws-14days-tg"   # 長さ 32 文字以内
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  target_type      = "instance"
  vpc_id           = aws_vpc.udemy_aws_14days.id

  # ヘルスチェック設定
  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5     # 秒
    interval            = 10    # 秒
  }

  tags = {
    Name = "udemy-aws-14days-tg"
  }
}

# web-1a を登録
resource "aws_lb_target_group_attachment" "tg_attach_web_1a" {
  target_group_arn = aws_lb_target_group.udemy_aws_14days_tg.arn
  target_id        = aws_instance.web_1a.id
  port             = 80
}

# web-1c を登録
resource "aws_lb_target_group_attachment" "tg_attach_web_1c" {
  target_group_arn = aws_lb_target_group.udemy_aws_14days_tg.arn
  target_id        = aws_instance.web_1c.id
  port             = 80
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

output "web_instance_id_1c" {
  description = "ID of the EC2 instance (web-1c)"
  value       = aws_instance.web_1c.id
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

output "tg_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.udemy_aws_14days_tg.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.udemy_aws_14days_alb.dns_name
}