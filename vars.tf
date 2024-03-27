variable "region" {
  type = string
  default = "us-east-1"
}

locals {
 availability_zones = ["${var.region}a", "${var.region}b"]
}

variable "aws-personal_security_key" {
    type = string
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCPOYg3ysyJemNb/6LdR8pJ1eCUE193exkxJ5DjAq08o+IrbwfvaoPemQnGHLRaTTXZKrR9QzclZN0WbYgqHImnj5ANOBflVPqr8a+QdoP7Z8NAEQrYv6Es7HPUVDp61rFCVLS/WZu1pP3HiuAw4xhennIRvB0UunfCSlCwirRnpECcVfwSoPqS+u/YrBpBy8ytAN7P8KYwE0FHdm5XKoPee918aD+SejxzxVgE2dkDFDx8wgrAHdhhrvArcuc9GkzEj7Rji5D6DlUTXQHy3C9/zEGlE3akpGc7U3/3ROoTf77dmPXHOjkoCnMIsdbR9QO+s8n/fvHhVi/I4u4XpJNI/QgOoYTehHrNeCSgBm8JyYt2GDYdWqjtPrzJhiq7fWN98rUmmLJIx54FRmuTrUxMZ8GW8ZedLIvNGhpdAZpBUcUZyvtIBGCOR0pmJcQ2UnATIJo8dbzzAqr9uHv8laBPOIyDUd9QxsNzjoZBwn7XkcllFDAVh5K8Oil6EXdGrM8= john@john-MS-7C56"
}

variable "ubuntu_ami" {
  type = string
  default = "ami-0c7217cdde317cfec"
}

variable "docker_blog_app_setup" {
    type = string
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

variable "wesamkhalildotuk_zone_id" {
  type = string
  default = "Z01064701HUUN21JB8C76"
}