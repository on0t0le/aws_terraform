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


resource "aws_security_group" "k8s-service-ports" {
  name        = "k8s_service_ports"
  description = "Service ports for k8s cluster"

  ### Kubernetes API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ### etcd server client API
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ### Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ### Flannel overlay network - udp backend
  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ### Flannel overlay network - vxlan backend
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  tags = {
    Name = "k8s service ports"
  }
}
