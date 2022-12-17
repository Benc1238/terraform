# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create an EC2 instance running Red Hat
resource "aws_instance" "example" {
  ami           = "ami-08e637cea2f053dfa"
  instance_type = "t2.micro"
}
