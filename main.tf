terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         	   = "wesam-devops-test"
    key              	 = "terraform/state/terraform.tfstate"
    region         	   = "us-east-1"
    encrypt        	   = true
    dynamodb_table     = "devops-test-state-lock"
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_security_group" "example" {
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["81.78.87.34/32"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "personal" {
  key_name   = "personal"
  public_key = var.aws-personal_security_key
}

resource "aws_instance" "example" {
    ami = var.ubuntu_ami
    instance_type = "t2.micro"
    security_groups = [aws_security_group.example.name]
    key_name = aws_key_pair.personal.key_name

    user_data = var.docker_blog_app_setup
}