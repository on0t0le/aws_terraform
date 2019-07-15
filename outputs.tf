output "Master_ip" {
  value = "${aws_instance.master-node.public_ip}"
}
