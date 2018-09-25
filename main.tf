### Backend definition

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

### Module Main

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"

  tags {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.aws_azs)}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 4, count.index)}"
  availability_zone       = "${var.aws_region}${var.aws_azs[count.index]}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.project_name}-public-${var.aws_region}${var.aws_azs[count.index]}"
    Zone = "${var.aws_region}${var.aws_azs[count.index]}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.aws_azs)}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 4, 15 - count.index)}"
  availability_zone       = "${var.aws_region}${var.aws_azs[count.index]}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.project_name}-private-${var.aws_region}${var.aws_azs[count.index]}"
    Zone = "${var.aws_region}${var.aws_azs[count.index]}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.project_name}-igw"
  }
}

data "aws_ami" "nat_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-hvm-*-x86_64-ebs"]
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${element(split(".", basename(var.aws_keypair_file)), 0)}"
  public_key = "${file(var.aws_keypair_file)}"
}

# resource "aws_security_group" "nat" {
#   vpc_id      = "${aws_vpc.vpc.id}"

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["${var.vpc_cidr}"]
#   }

#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     cidr_blocks     = ["0.0.0.0/0"]
#   }

#   tags {
#     Name = "nat"
#   }
# }

resource "aws_instance" "nat" {
  ami               = "${data.aws_ami.nat_ami.id}"
  instance_type     = "${var.nat_instance_type}"
  count             = "${length(var.aws_azs)}"
  subnet_id         = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  key_name          = "${aws_key_pair.key_pair.key_name}"
  availability_zone = "${var.aws_region}${var.aws_azs[count.index]}"
  source_dest_check = false

  tags {
    Name = "${var.project_name}-nat-${var.aws_region}${var.aws_azs[count.index]}"
  }
}

resource "aws_eip" "eip" {
  vpc        = true
  instance   = "${element(aws_instance.nat.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.gateway"]
  count      = "${length(var.aws_azs)}"

  tags {
    Name = "${var.project_name}-eip-${var.aws_region}${var.aws_azs[count.index]}"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${element(aws_instance.nat.*.id, count.index)}"
  allocation_id = "${element(aws_eip.eip.*.id, count.index)}"
  count         = "${length(var.aws_azs)}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }

  tags {
    Name = "${var.project_name}-route-table-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  count  = "${length(var.aws_azs)}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${element(aws_instance.nat.*.id, count.index)}"
  }

  tags {
    Name = "${var.project_name}-route-table-private-${var.aws_region}${var.aws_azs[count.index]}"
  }
}
