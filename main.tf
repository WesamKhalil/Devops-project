terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "wesam-devops-test"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "devops-test-state-lock"
  }
}

provider "aws" {
  region = var.region
}

resource "aws_key_pair" "personal_kp" {
  key_name   = "tf-personal-kp"
  public_key = var.aws_personal_ssh_public_key
}

resource "aws_lb_target_group" "blog_web_server_lb_tg" {
  name     = "tf-blog-web-server-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_autoscaling_group" "bar" {
  vpc_zone_identifier = [aws_subnet.public_us_east_1a.id, aws_subnet.public_us_east_1b.id]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1

  launch_template {
    id      = aws_launch_template.blog_web_server_launch_template.id
    version = "$Latest"
  }
}

resource "aws_lb" "blog_web_server_lb" {
  name               = "tf-blog-web-server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.blog_web_server_sg.id]
  subnets            = [aws_subnet.public_us_east_1a.id, aws_subnet.public_us_east_1b.id]
}

resource "aws_lb_listener" "blog_web_server_lb_listener_http" {
  load_balancer_arn = aws_lb.blog_web_server_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "blog_web_server_lb_listener_https" {
  load_balancer_arn = aws_lb.blog_web_server_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.web_domain_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blog_web_server_lb_tg.arn
  }
}


resource "aws_route53_record" "www" {
  zone_id = var.main_route53_zone_id
  name    = "www.wesamkhalil.uk"
  type    = "A"

  alias {
    name                   = aws_lb.blog_web_server_lb.dns_name
    zone_id                = aws_lb.blog_web_server_lb.zone_id
    evaluate_target_health = true
  }
}