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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-main"
  }
}

resource "aws_subnet" "public_us_east_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-public-us-east-1a"
  }
}

resource "aws_subnet" "private_us_east_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = local.availability_zones[1]

  tags = {
    Name = "tf-private-us-east-1b"
  }
}

resource "aws_security_group" "blog_web_server_sg" {

  name   = "tf-blog-web-server-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.personal_cidr_ip_address]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "blog_web_server_instance" {
  ami                    = var.ubuntu_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.blog_web_server_sg.id]
  key_name               = aws_key_pair.personal_kp.key_name
  availability_zone      = local.availability_zones[0]
  subnet_id              = aws_subnet.public_us_east_1a.id

  user_data = var.docker_blog_app_setup

  tags = {
    Name = "tf-blog-web-server-instance"
  }
}

resource "aws_internet_gateway" "default_internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-default-internet-gateway"
  }
}

resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_eip.nat_eip]
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_us_east_1a.id

  tags = {
    "Name" = "tf-nat-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_internet_gateway.id
  }

  tags = {
    Name = "tf-public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  depends_on = [aws_nat_gateway.nat_gateway]

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "tf-private-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_route_table" {
  subnet_id      = aws_subnet.public_us_east_1a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_route_table" {
  subnet_id      = aws_subnet.private_us_east_1b.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_lb_target_group" "blog_web_server_lb_tg" {
  name     = "tf-blog-web-server-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
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
  subnets            = [aws_subnet.public_us_east_1a.id, aws_subnet.private_us_east_1b.id]
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