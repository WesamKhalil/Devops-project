variable "region" {
  type    = string
  default = "us-east-1"
}

locals {
  availability_zones = ["${var.region}a", "${var.region}b"]
}

variable "personal_cidr_ip_address" {
  type = string
}

variable "aws_personal_ssh_public_key" {
  type = string
}

variable "ubuntu_ami" {
  type    = string
  default = "ami-0c7217cdde317cfec"
}

variable "docker_blog_app_setup" {
  type    = string
  default = <<-EOL
      #!/bin/bash -xe

      sudo apt-get update -y
      sudo apt-get install ca-certificates curl -y
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc

      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update -y
      sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

      docker pull wesamkhalil/blog-app:v1

      docker run -d -p 80:3000 wesamkhalil/blog-app:v1
    EOL
}

variable "main_route53_zone_id" {
  type = string
}

variable "web_domain_certificate_arn" {
  type = string
}