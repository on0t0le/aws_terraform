### Load key to AWS
resource "aws_key_pair" "k8s-master" {
  key_name   = "k8s-master"
  public_key = "${file("${var.public_key}")}"
}
### Create Master node
resource "aws_instance" "master-node" {
  ami             = "${data.aws_ami.amazon-linux-ami.id}"
  instance_type   = "t2.micro"
  key_name        = "k8s-master"
  security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.k8s-service-ports.name}"]

  tags = {
    Name = "master-node"
  }
}

### Create Worker node
resource "aws_instance" "worker-node" {
  ami             = "${data.aws_ami.amazon-linux-ami.id}"
  instance_type   = "t2.micro"
  key_name        = "k8s-master"
  security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.k8s-service-ports.name}"]

  tags = {
    Name = "worker-node"
  }
}
