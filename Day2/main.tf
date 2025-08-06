provider "aws" {
  region = "ap-northeast-1"
}

# --- AMI を SSM から正しく取得（kernel-6.1 を確実に取る） ---
data "aws_ssm_parameter" "al2023_kernel61" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# --- デフォルトVPC/サブネット（無ければ作る, あれば拾う） ---
resource "aws_default_vpc" "this" {}

# --- インターネットゲートウェイを明示的に作成 ---
resource "aws_internet_gateway" "this" {
  vpc_id = aws_default_vpc.this.id

  tags = {
    Name = "main-igw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_default_subnet" "az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

# --- デフォルトルートテーブルを更新してインターネットゲートウェイへのルートを追加 ---
resource "aws_default_route_table" "this" {
  default_route_table_id = aws_default_vpc.this.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# --- セキュリティグループ（SSH禁止：ingress を書かない） ---
resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Security group with no SSH access"
  vpc_id      = aws_default_vpc.this.id

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
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh"
  }
}

# --- EC2 ---
resource "aws_instance" "amazon_linux" {
  ami                    = data.aws_ssm_parameter.al2023_kernel61.value
  instance_type          = "t2.micro"
  key_name               = "udemy-aws-14days"
  subnet_id              = aws_default_subnet.az1.id
  vpc_security_group_ids = [aws_security_group.ssh.id]

  # ストレージ: 8GB, gp3
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "AmazonLinux2023Test"
  }
}

# --- AMI作成（EC2インスタンスから） ---
resource "aws_ami_from_instance" "custom_ami" {
  name               = "Sample EC2 AMI"
  source_instance_id = aws_instance.amazon_linux.id
  description        = "Custom AMI created from AmazonLinux2023Test instance"

  tags = {
    Name        = "CustomAmazonLinux2023AMI"
    CreatedFrom = "AmazonLinux2023Test"
    CreatedAt   = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  }
}

# --- カスタムAMIから作成するEC2 ---
resource "aws_instance" "amazon_linux_from_ami" {
  ami                    = aws_ami_from_instance.custom_ami.id
  instance_type          = "t2.micro"
  key_name               = "udemy-aws-14days"
  subnet_id              = aws_default_subnet.az1.id
  vpc_security_group_ids = [aws_security_group.ssh.id]

  # ストレージ: 8GB, gp3
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "AmazonLinux2023TestAMI"
  }

  # AMIが作成されてから実行されるように依存関係を明示
  depends_on = [aws_ami_from_instance.custom_ami]
}

# --- Elastic IP for カスタムAMIから作成したEC2 ---
resource "aws_eip" "amazon_linux_ami_eip" {
  domain = "vpc"

  tags = {
    Name = "AmazonLinux2023TestAMI-EIP"
  }
}

# --- Elastic IPをEC2にアタッチ ---
resource "aws_eip_association" "amazon_linux_ami_eip_assoc" {
  instance_id   = aws_instance.amazon_linux_from_ami.id
  allocation_id = aws_eip.amazon_linux_ami_eip.id
}

