variable "access_key" {}
variable "secret_key" {}

variable "aws_key_name" {}

variable "region" {
  default = "us-east-1"
}

variable "ami" {
  default = "ami-0b33d91d"
}

variable "instance_type" {
  default = "t2.micro"
}

