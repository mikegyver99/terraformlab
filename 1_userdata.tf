## Copied from CloudFormation Lab work https://learn.cantrill.io/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Set your region here or via AWS_REGION environment variable
  # region = "us-east-1"
}

# Variables
variable "message" {
  description = "Message for HTML page"
  type        = string
  default     = "Cats are the best"
}

# Fetch latest Amazon Linux 2 AMI (equivalent to SSM parameter)
data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Security Group
resource "aws_security_group" "instance_sg" {
  name        = "A4L-UserData-SG"
  description = "Enable SSH and HTTP access via port 22 IPv4 & port 80 IPv4"

  ingress {
    description = "Allow SSH IPv4 IN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP IPv4 IN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 Bucket
resource "aws_s3_bucket" "bucket" {}

# EC2 Instance
resource "aws_instance" "instance" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ssm_parameter.latest_ami.value
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    Name = "A4L-UserData Test"
  }

  user_data = <<-EOF
    #!/bin/bash -xe
    yum -y update
    yum -y upgrade
    # simulate some other processes here
    sleep 300
    # Continue
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<html><head><title>Amazing test page</title></head><body><h1><center>${var.message}</center></h1></body></html>" > /var/www/html/index.html
  EOF
}

# Outputs
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.instance.public_ip
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.bucket.id
}
