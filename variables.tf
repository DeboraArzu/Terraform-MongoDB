variable "access_key" {}
variable "secret_key" {}

variable "aws_key_name" {}

variable "region" {
  default = "us-east-1"
}

variable "ami" {
  default     = "ami-0080e4c5bc078760e"
  description = "Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_type_mongo" {
  default = "m4.xlarge"
}
