data "aws_ami" "amazon-linux-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
