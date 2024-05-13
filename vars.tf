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

variable "main_route53_zone_id" {
  type = string
}

variable "web_domain_certificate_arn" {
  type = string
}