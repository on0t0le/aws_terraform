output "Master_ip" {
  value = "${aws_instance.master-node.public_ip}"
}
output "Worker_ip" {
  value = "${aws_instance.worker-node.public_ip}"
}