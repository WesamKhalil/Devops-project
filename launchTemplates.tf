resource "aws_launch_template" "blog_web_server_launch_template" {
  name = "tf-blog-webserver-launch-template"

  instance_type = "t2.micro"
  image_id = var.ubuntu_ami
  vpc_security_group_ids = [aws_security_group.blog_web_server_sg.id]
  key_name               = aws_key_pair.personal_kp.key_name

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "tf-blog-web-server-instance"
    }
  }

  user_data = filebase64("${path.module}/blog-web-server-installation.sh")
}