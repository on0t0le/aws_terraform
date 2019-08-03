### Load key to AWS
resource "aws_key_pair" "k8s-master" {
  key_name   = "k8s-master"
  public_key = "${file("${var.public_key}")}"
}

### Create master sh-script
data "template_file" "master-userdata" {
  template = "${file("master.sh")}"

  vars = {
    k8stoken = "${var.k8stoken}"
  }
}

### Create worker sh-script
data "template_file" "worker-userdata" {
  template = "${file("worker.sh")}"

  vars = {
    k8stoken = "${var.k8stoken}"
    masterIP = "${aws_instance.master-node.private_ip}"
  }
}

### Create IAM role
resource "aws_iam_role" "role" {
  name = "${var.cluster-name}-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

### Create policy for IAM role
resource "aws_iam_policy" "policy" {
  name = "${var.cluster-name}-autoscaling-policy"
  path = "/"
  description = "Policy for ${var.cluster-name} cluster to allow cluster autoscaling to work"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

### Attach policy to role
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

### Create IAM profile
resource "aws_iam_instance_profile" "profile" {
  name = "${var.cluster-name}-instance-profile"
  role = "${aws_iam_role.role.name}"
}

### Create Master node
resource "aws_instance" "master-node" {
  ami                  = "${data.aws_ami.amazon-linux-ami.id}"
  instance_type        = "t2.micro"
  key_name             = "k8s-master"
  security_groups      = ["${aws_security_group.ssh.name}", "${aws_security_group.k8s-service-ports.name}"]
  user_data            = "${data.template_file.master-userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = "${aws_instance.master-node.public_ip}"
    private_key = "${file(var.private_key)}"
  }

  provisioner "file" {
    source      = "cluster_autoscaler/"
    destination = "/home/ec2-user"
  }
  provisioner "file" {
    source      = "hpa/k8s-prom-hpa/"
    destination = "/home/ec2-user"
  }
  
  tags = {
    Name                                        = "master-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}

### Create launch-template for worker node
resource "aws_launch_template" "worker-node" {
  name          = "worker-node-template"
  image_id      = "${data.aws_ami.amazon-linux-ami.id}"
  instance_type = "t2.micro"
  key_name      = "k8s-master"
  user_data     = "${base64encode(data.template_file.worker-userdata.rendered)}"

  iam_instance_profile {
    name = "${aws_iam_instance_profile.profile.name}"
  }

  security_group_names = [
    "${aws_security_group.ssh.name}",
    "${aws_security_group.k8s-service-ports.name}"
  ]
}

### Create ASG for working nodes
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
      key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${var.cluster-name}"
      value               = "owned"
      propagate_at_launch = true
    }
  ]
}
