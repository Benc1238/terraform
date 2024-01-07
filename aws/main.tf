provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraformVPC"
  }
}

resource "aws_subnet" "pub-sub" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-Subnet-Terraform"
  }
}

resource "aws_subnet" "priv-sub" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Name = "private-Subnet-Terraform"
  }
}

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.222.231.103/32"]
  }

  tags = {
    Name = "bastion_sg"
  }
}

resource "aws_instance" "bastion" {
  ami           = "ami-08e637cea2f053dfa"
  instance_type = "t2.micro"
  key_name      = "vockey"
  subnet_id     = aws_subnet.pub-sub.id
  security_group_names = [aws_security_group.bastion_sg.name]

  tags = {
    Name = "bastion"
  }
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_sg"
  }
}

resource "aws_instance" "app_instance" {
  ami           = "ami-08e637cea2f053dfa"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.priv-sub.id
  security_group_names = [aws_security_group.app_sg.name]
  key_name      = "vockey"

  tags = {
    Name = "app-instance"
  }
}

// Reszta kodu pozostaje bez zmian
