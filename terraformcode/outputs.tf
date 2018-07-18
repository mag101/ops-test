output "master.ip" {
  value = "${aws_instance.master.*.public_ip}"
}
output "slave.ip" {
  value = "${aws_instance.slave.*.public_ip}"
}
output "jenkins.ip" {
  value = "${aws_instance.jenkins.*.public_ip}"
}
