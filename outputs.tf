output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "private_subnets" {
  value = ["${aws_subnet.private_subnet.*.id}"]
}

output "public_subnets" {
  value = ["${aws_subnet.public_subnet.*.id}"]
}

output "nat_ami_id" {
  value = "${data.aws_ami.nat_ami.id}"
}

output "nat_ids" {
  value = ["${aws_instance.nat.*.id}"]
}

output "eips" {
  value = ["${aws_eip.eip.*.id}"]
}

output "public_table" {
  value = "${aws_route_table.public.id}"
}

output "private_table" {
  value = ["${aws_route_table.private.*.id}"]
}
