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
    cidr_blocks = ["IP/32"]
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
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    #security_groups = [aws_security_group.bastion_sg.id]
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
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name      = "vockey"

  tags = {
    Name = "app-instance"
  }
}

resource "aws_launch_configuration" "app_lc" {
  name                 = "app-launch-config"
  image_id             = "ami-08e637cea2f053dfa"
  instance_type        = "t2.micro"
  key_name             = "vockey"
  security_groups      = [aws_security_group.app_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier = [aws_subnet.priv-sub.id]
  launch_configuration = aws_launch_configuration.app_lc.name
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub-sub.id, aws_subnet.priv-sub.id]
  security_groups    = [aws_security_group.app_sg.id]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.priv-sub.id, aws_subnet.pub-sub.id]
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.vpc.id

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
    Name = "db_sg"
  }
}

resource "aws_db_instance" "rds" {
  identifier           = "my-rds-instance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}
