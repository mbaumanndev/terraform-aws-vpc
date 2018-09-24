output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "private_subnets" {
  value = [ "${aws_subnet.private_subnet.*.id}" ]
}

output "public_subnets" {
  value = [ "${aws_subnet.public_subnet.*.id}" ]
}

output "nat_ami_id" {
  value = "${data.aws_ami.nat_ami.id}"
}

output "nat_ids" {
  value = [ "${aws_instance.nat.*.id}" ]
}
