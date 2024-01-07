provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/24"
    tags = {
        Name = "terraformVPC"
    }
}

resource "aws_subnet" "pub-sub" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.0.0/25"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1"
    tags = {
        Name = "public-Subnet-Terraform"
    }
}

resource "aws_subnet" "priv-sub" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.0.128/25"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1"
    tags = {
        Name = "private-Subnet-Terraform"
    }
}

resource "aws_route_table" "public-route" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "pub-route"
    }
}

resource "aws_route_table" "private-route" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "priv-route"
    }
}

resource "aws_route_table_association" "public-association" {
    route_table_id = aws_route_table.public-route.id
    subnet_id      = aws_subnet.pub-sub.id
}

resource "aws_route_table_association" "private-association" {
    route_table_id = aws_route_table.private-route.id
    subnet_id      = aws_subnet.priv-sub.id
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "igwFromTerraform"
    }
}

resource "aws_route" "route-pub" {
    route_table_id         = aws_route_table.public-route.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.vpc.id
    name   = "terraformSG"
    ingress {
        from_port   = 0
        protocol    = "-1"
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        protocol    = "-1"
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "bastion" {
  ami           = "ami-xxxxxxxxxxxxxxxxx" # AMI for bastion host
  instance_type = "t2.micro"
  key_name      = "vockey"
  subnet_id     = aws_subnet.pub-sub.id
  security_group_ids = [aws_security_group.sg.id]
  tags = {
    Name = "bastion"
  }
}

resource "aws_instance" "app_instance" {
  ami           = "ami-xxxxxxxxxxxxxxxxx" # AMI for your application
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.priv-sub.id
  security_group_ids = [aws_security_group.sg.id]
  key_name      = "vockey"
  tags = {
    Name = "app-instance"
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier = [aws_subnet.priv-sub.id]
  launch_configuration = aws_instance.app_instance.id
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
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

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "db-sg"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg.id]
  }
}

resource "aws_db_instance" "rds" {
  identifier           = "my-rds-instance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydatabase"
  username             = "admin"
  password             = "password"
  publicly_accessible  = false
  db_subnet_group_name = "your_db_subnet_group"
  vpc_security_group_ids = [aws_security_
