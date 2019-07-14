### Creating security groups
resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow ssh for k8s"

  ingress {    
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"    
    cidr_blocks = ["${var.myIP}"]
  }

  tags = {
    Name = "Allow ssh k8s"
  }
}