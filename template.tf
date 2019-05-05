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

resource "aws_internet_gateway" "nat-gateway" {
  vpc_id = "${aws_vpc.MongoVpc.id}"
}

# public subnets
resource "aws_subnet" "us-east-1a-public" {
  vpc_id            = "${aws_vpc.MongoVpc.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "us-east-1a-public"
  }
}

resource "aws_subnet" "us-east-1b-public" {
  vpc_id            = "${aws_vpc.MongoVpc.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "us-east-1b-public"
  }
}

resource "aws_subnet" "us-east-1c-public" {
  vpc_id            = "${aws_vpc.MongoVpc.id}"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "us-east-1c-public"
  }
}

# Routing table for public subnets

resource "aws_route_table" "us-east-1-public" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.nat-gateway.id}"
  }

  tags = {
    Name = "us-east-1-public"
  }
}

resource "aws_route_table_association" "us-east-1a-public" {
  subnet_id      = "${aws_subnet.us-east-1a-public.id}"
  route_table_id = "${aws_route_table.us-east-1-public.id}"
}

resource "aws_route_table_association" "us-east-1b-public" {
  subnet_id      = "${aws_subnet.us-east-1b-public.id}"
  route_table_id = "${aws_route_table.us-east-1-public.id}"
}

resource "aws_route_table_association" "us-east-1c-public" {
  subnet_id      = "${aws_subnet.us-east-1c-public.id}"
  route_table_id = "${aws_route_table.us-east-1-public.id}"
}

# Private subsets
resource "aws_subnet" "us-east-1a-private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "us-east-1a-private"
  }
}

resource "aws_subnet" "us-east-1b-private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "us-east-1b-private"
  }
}

resource "aws_subnet" "us-east-1c-private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "us-east-1c-private"
  }
}

# Routing table for private subnets

resource "aws_route_table" "us-east-1-private" {
  vpc_id = "${aws_vpc.MongoVpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${aws_instance.Mongoinstance.id}"
  }

  tags = {
    Name = "us-east-1-private"
  }
}

resource "aws_route_table_association" "us-east-1a-private" {
  subnet_id      = "${aws_subnet.us-east-1a-private.id}"
  route_table_id = "${aws_route_table.us-east-1-private.id}"
}

resource "aws_route_table_association" "us-east-1b-private" {
  subnet_id      = "${aws_subnet.us-east-1b-private.id}"
  route_table_id = "${aws_route_table.us-east-1-private.id}"
}

resource "aws_route_table_association" "us-east-1c-private" {
  subnet_id      = "${aws_subnet.us-east-1c-private.id}"
  route_table_id = "${aws_route_table.us-east-1-private.id}"
}

resource "aws_instance" "Mongoinstance" {
  ami                         = "ami-0b33d91d"                       # Amazon Linux AMI
  availability_zone           = "us-east-1b"
  instance_type               = "t2.micro"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us-east-1b-public.id}"
  associate_public_ip_address = true
  source_dest_check           = false

  tags {
    Name = "Mongoinstace"
  }
}

# resource "aws_eip" "nat" {
#   instance = "${aws_instance.Mongoinstance.id}"
#   vpc      = true
# }

resource "aws_security_group" "MongSG" {
  name        = "MongSG"
  description = "Allow services from the private subnet through NAT"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.us-east-1b-private.cidr_block}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "ssh"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.MongoVpc.id}"

  tags {
    Name = "MongSG"
  }
}

#output
output "public_ip" {
  value = "${aws_instance.Mongoinstance.public_ip}"
}

output "public_dns" {
  value = "${aws_instance.Mongoinstance.public_dns}"
}
