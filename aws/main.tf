provider "aws" {
  region = "us-east-1"
}

# Create an EC2
resource "aws_instance" "publ-EC2" {
  ami = "ami-08e637cea2f053dfa"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.pub-sub.id
  security_groups = [aws_security_group.sg.id]
  key_name = "vockey"
  tags = {
    Name = "Terraform-pub-ec2"
  }

}

resource "aws_instance" "priv-EC2" {
  ami = "ami-08e637cea2f053dfa"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.priv-sub.id
  security_groups = [aws_security_group.sg.id]
  key_name = "vockey"
  tags = {
    Name = "Terraform-priv-ec2"
  }

}

resource "aws_vpc" "vpc" {
    cird_block = "10.0.0.0/24"
    tags - {
        Name = "terraformVPC"
    }
}

resource "aws_subnet" "pub-sub" {
    vpc_id = aws_vpc.vpc.id
    cird_block = "10.0.0.0/25"
    map_publiv_ip_on_launch = true
    availability_zone = "us-east-1"
    tags = {
        Name = "public-Subnet-Terraform"
    }
}

resource "aws_subnet" "priv-sub" {
    vpc_id = aws_vpc.vpc.id
    cird_block = "10.0.0.128/25"
    map_publiv_ip_on_launch = true
    availability_zone = "us-east-1"
    tags = {
        Name = "private-Subnet-Terraform"
    }
}

resource "aws_route_table" "public-route"{
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "pub-route"
    }
}
resource "aws_route_table" "private-route"{
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "priv-route"
    }
}

resource "aws_route_table_association" "public-association"{
    rout_table_id = aws_route_table.public-route.id
    subnet_it = aws_subnet.pub-sub.id
}

resource "aws_route_table_association" "private-association"{
    rout_table_id = aws_route_table.private-route.id
    subnet_it = aws_subnet.priv-sub.id
}

resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "igwFromTerraform"
    }
}

resource "aws_route" "route-pub"{
    rout_table_id = aws_route_table.public-route.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

resource "aws_security_group" "sg"{
    vpc_id = aws_vpc.vpc.id
    name = "terraformSG"
    ingress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cird_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        protocol = "-1"
        to_port = 0
        cird_blocks = ["0.0.0.0/0"]
    }
}

