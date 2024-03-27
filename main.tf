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
    region = var.region
}

resource "aws_security_group" "blog_web_server_sg" {

  name = "tf-blog-web-server-sg"

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

resource "aws_key_pair" "personal_kp" {
  key_name   = "tf-personal-kp"
  public_key = var.aws-personal_security_key
}

resource "aws_instance" "blog_web_server_instance" {
    ami = var.ubuntu_ami
    instance_type = "t2.micro"
    security_groups = [aws_security_group.blog_web_server_sg.name]
    key_name = aws_key_pair.personal_kp.key_name
    availability_zone = local.availability_zones[0]

    user_data = var.docker_blog_app_setup

    tags = {
      Name = "tf-blog-web-server-instance"
    }
}

resource "aws_default_vpc" "default" {
}

resource "aws_default_subnet" "default_us_east_1a" {
  availability_zone = local.availability_zones[0]
}

resource "aws_default_subnet" "default_us_east_1b" {
  availability_zone = local.availability_zones[1]
}

resource "aws_lb_target_group" "blog_web_server_lb_tg" {
  name     = "tf-blog-web-server-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_target_group_attachment" "blog_web_server_lb_tga" {
 target_group_arn = aws_lb_target_group.blog_web_server_lb_tg.arn
 target_id        = aws_instance.blog_web_server_instance.id
 port             = 80
}

resource "aws_lb" "blog_web_server_lb" {
  name               = "tf-blog-web-server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.blog_web_server_sg.id]
  subnets            = [aws_default_subnet.default_us_east_1a.id, aws_default_subnet.default_us_east_1b.id]
}

resource "aws_lb_listener" "blog_web_server_lb_listener" {
 load_balancer_arn = aws_lb.blog_web_server_lb.arn
 port              = "80"
 protocol          = "HTTP"

 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.blog_web_server_lb_tg.arn
 }
}


resource "aws_route53_record" "www" {
  zone_id = var.wesamkhalildotuk_zone_id
  name    = "www.wesamkhalil.uk"
  type    = "A"

  alias {
    name                   = aws_lb.blog_web_server_lb.dns_name
    zone_id                = aws_lb.blog_web_server_lb.zone_id
    evaluate_target_health = true
  }
}