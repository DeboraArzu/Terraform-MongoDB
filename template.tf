provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "MongoVpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MongoVpc"
  }
}

resource "aws_internet_gateway" "Internet_GW" {
  vpc_id = "${aws_vpc.MongoVpc.id}"
}

# public subnets
resource "aws_subnet" "us_east_1a_public" {
  vpc_id                  = "${aws_vpc.MongoVpc.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "us_east_1a_public"
  }
}

resource "aws_subnet" "us_east_1b_public" {
  vpc_id                  = "${aws_vpc.MongoVpc.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "us_east_1b_public"
  }
}

resource "aws_subnet" "us_east_1c_public" {
  vpc_id                  = "${aws_vpc.MongoVpc.id}"
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "us_east_1c_public"
  }
}

# Routing table for public subnets

resource "aws_route_table" "us-east-1-public" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.Internet_GW.id}"
  }

  tags = {
    Name = "us-east-1-public"
  }
}

resource "aws_route_table_association" "us_east_1a_public" {
  subnet_id      = "${aws_subnet.us_east_1a_public.id}"
  route_table_id = "${aws_route_table.us-east-1-public.id}"
}

resource "aws_route_table_association" "us_east_1b_public" {
  subnet_id      = "${aws_subnet.us_east_1b_public.id}"
  route_table_id = "${aws_route_table.us-east-1-public.id}"
}

resource "aws_route_table_association" "us_east_1c_public" {
  subnet_id      = "${aws_subnet.us_east_1c_public.id}"
  route_table_id = "${aws_route_table.us-east-1-public.id}"
}

# Private subsets
resource "aws_subnet" "us_east_1a_private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "us_east_1a_private"
  }
}

resource "aws_subnet" "us_east_1b_private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "us_east_1b_private"
  }
}

resource "aws_subnet" "us_east_1c_private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "us_east_1c_private"
  }
}

# Routing table for private subnets

resource "aws_eip" "nat_1a" {
  # instance = "${aws_instance.Mongoinstance_1a.id}"
  vpc = true
}

resource "aws_nat_gateway" "Nat_GW" {
  allocation_id = "${aws_eip.nat_1a.id}"
  subnet_id     = "${aws_subnet.us_east_1a_public.id}"
  depends_on    = ["aws_internet_gateway.Internet_GW"]

  tags = {
    Name = "Nat_GW"
  }
}

# NAT GateWay for the private instances

resource "aws_route_table" "us-east-1-private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.Nat_GW.id}"
  }

  tags = {
    Name = "us-east-1-private"
  }
}

resource "aws_route_table_association" "us_east_1a_private" {
  subnet_id      = "${aws_subnet.us_east_1a_private.id}"
  route_table_id = "${aws_route_table.us-east-1-private.id}"
}

resource "aws_route_table_association" "us_east_1b_private" {
  subnet_id      = "${aws_subnet.us_east_1b_private.id}"
  route_table_id = "${aws_route_table.us-east-1-private.id}"
}

resource "aws_route_table_association" "us_east_1c_private" {
  subnet_id      = "${aws_subnet.us_east_1c_private.id}"
  route_table_id = "${aws_route_table.us-east-1-private.id}"
}

# Instances in a private subnet
resource "aws_instance" "Mongoinstance_1a" {
  ami                         = "${var.ami}"                          # Amazon Linux AMI
  availability_zone           = "us-east-1a"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us_east_1a_private.id}"
  associate_public_ip_address = false
  source_dest_check           = false
  user_data                   = "${file("install_mongoDB.sh")}"

  tags {
    Name = "Mongoinstace 1a private"
  }
}

resource "aws_instance" "Mongoinstance_1b" {
  ami                         = "${var.ami}"                          # Amazon Linux AMI
  availability_zone           = "us-east-1b"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us_east_1b_private.id}"
  associate_public_ip_address = false
  source_dest_check           = false
  user_data                   = "${file("install_mongoDB.sh")}"

  tags {
    Name = "Mongoinstace 1b private"
  }
}

resource "aws_instance" "Mongoinstance_1c" {
  ami                         = "${var.ami}"                          # Amazon Linux AMI
  availability_zone           = "us-east-1c"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us_east_1c_private.id}"
  associate_public_ip_address = false
  source_dest_check           = false
  user_data                   = "${file("install_mongoDB.sh")}"

  tags {
    Name = "Mongoinstace 1c private"
  }
}

resource "aws_security_group" "MongSG" {
  name        = "MongSG"
  description = "Allow the Bastion to SSH"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.BastionSG.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.MongoVpc.id}"

  tags {
    Name = "MongSG"
  }
}

resource "aws_security_group" "BastionSG" {
  name        = "BastionSG"
  description = "Allow services from the private subnet through NAT"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.MongoVpc.id}"

  tags {
    Name = "BastionSG"
  }
}

# Bastion in AutoScaling Group
resource "aws_launch_template" "Bastion_LT" {
  name                   = "bastion_LT"
  image_id               = "${var.ami}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.BastionSG.id}"]

  tags = {
    Name = "Bastion_LT"
  }
}

resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1a"]
  max_size           = 3
  min_size           = 1

  launch_template {
    id      = "${aws_launch_template.Bastion_LT.id}"
    version = "$Latest"
  }

  tags = {
    name = "Bastion"
  }
}

#output
output "bastion_public_ip" {
  value = "${aws_instance.Bastion.public_ip}"
}

output "Mongo1_private_ip" {
  value = "${aws_instance.Mongoinstance_1a.private_ip}"
}

output "Mongo2_private_ip" {
  value = "${aws_instance.Mongoinstance_1b.private_ip}"
}

output "Mongo3_private_ip" {
  value = "${aws_instance.Mongoinstance_1c.private_ip}"
}
