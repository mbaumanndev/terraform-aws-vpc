variable "aws_region" {
  type        = "string"
  description = "Region to use"
  default     = "us-east-1"
}

variable "project_name" {
  type        = "string"
  description = "Project name"
  default     = "terraform-aws"
}

variable "vpc_name" {
  type        = "string"
  description = "Name of the VPC"
  default     = "vpc"
}

variable "vpc_cidr" {
  type        = "string"
  description = "CIDR adress for the vpc"
}

variable "aws_azs" {
  type        = "list"
  description = "List of AZs to use to create our stuff. Only the last letter."
  default     = ["a", "b", "c"]
}

variable "aws_keypair_file" {
  type        = "string"
  description = "Path of the public key"
}

variable "nat_instance_type" {
  type        = "string"
  description = "Type of instance to user for NAT servers"
}
