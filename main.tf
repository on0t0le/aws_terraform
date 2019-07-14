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

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = "${aws_instance.master-node.public_ip}"
    private_key = "${file(var.private_key)}"
  }

  provisioner "remote-exec" {
    inline = ["ls ~/"]
  }

  provisioner "file" {
    source      = "cluster_autoscaler/"
    destination = "/home/ec2-user"
  }

  tags = {
    Name = "master-node"
  }
}

# ### Create Worker node
# resource "aws_instance" "worker-node" {
#   ami             = "${data.aws_ami.amazon-linux-ami.id}"
#   instance_type   = "t2.micro"
#   key_name        = "k8s-master"
#   security_groups = ["${aws_security_group.ssh.name}", "${aws_security_group.k8s-service-ports.name}"]

#   tags = {
#     Name = "worker-node"
#   }
# }

resource "aws_launch_template" "worker-node" {
  name          = "worker-node-template"
  image_id      = "${data.aws_ami.amazon-linux-ami.id}"
  instance_type = "t2.micro"
  key_name      = "k8s-master"

  security_group_names = [
    "${aws_security_group.ssh.name}",
    "${aws_security_group.k8s-service-ports.name}"
  ]
}

resource "aws_autoscaling_group" "k8s-cluster-group" {
  name             = "k8s-group"
  desired_capacity = 1
  min_size         = 1
  max_size         = 3

  availability_zones = ["${aws_instance.master-node.availability_zone}"]

  launch_template {
    id = "${aws_launch_template.worker-node.id}"
  }

  tags = [
    {
      key                 = "Name"
      value               = "worker-node"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/cluster-autoscaler/enabled"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "k8s.io/cluster-autoscaler/k8s-cluster"
      value               = "true"
      propagate_at_launch = true
    }
  ]
}
