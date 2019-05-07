provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = "${file("./key/public_terraform.pem")}"
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

# MongoDB in a Cluster 
resource "aws_instance" "Mongo_Master" {
  ami                         = "${var.ami}"                                                                                # Amazon Linux AMI
  availability_zone           = "us-east-1a"
  instance_type               = "${var.instance_type_mongo}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us_east_1a_private.id}"
  associate_public_ip_address = false
  source_dest_check           = false
  user_data                   = "${data.template_file.user_data.rendered}"
  depends_on                  = ["aws_instance.Mongo_Slave1", "aws_instance.Mongo_Slave2", "aws_autoscaling_group.Bastion"]

  connection {
    bastion_host = "${aws_eip.eip_bastion.public_ip}"
    host         = "${self.private_ip}"
    type         = "ssh"
    user         = "ec2-user"
    private_key  = "${file("key/opsworks.pem")}"
  }

  provisioner "file" {
    source      = "./configuration_files/mongod.conf"
    destination = "/home/ec2-user/mongod.conf"
  }

  tags {
    Name = "Mongo_Master"
  }
}

data "template_file" "user_data" {
  template = "${file("./scripts/install_mongoMaster.sh")}"

  vars {
    INSTANCE1 = "${aws_instance.Mongo_Slave1.private_ip}"
    INSTANCE2 = "${aws_instance.Mongo_Slave2.private_ip}"
  }
}

resource "aws_instance" "Mongo_Slave1" {
  ami                         = "${var.ami}"                                 # Amazon Linux AMI
  availability_zone           = "us-east-1b"
  instance_type               = "${var.instance_type_mongo}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us_east_1b_private.id}"
  associate_public_ip_address = false
  source_dest_check           = false
  user_data                   = "${file("./scripts/install_mongoSlave.sh")}"

  tags {
    Name = "Mongo_Slave_1"
  }
}

resource "aws_instance" "Mongo_Slave2" {
  ami                         = "${var.ami}"                                 # Amazon Linux AMI
  availability_zone           = "us-east-1c"
  instance_type               = "${var.instance_type_mongo}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.MongSG.id}"]
  subnet_id                   = "${aws_subnet.us_east_1c_private.id}"
  associate_public_ip_address = false
  source_dest_check           = false
  user_data                   = "${file("./scripts/install_mongoSlave.sh")}"

  tags {
    Name = "Mongo_Slave_2"
  }
}

# Security Groups
resource "aws_security_group" "MongSG" {
  name        = "MongSG"
  description = "Allow the Bastion to SSH"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.BastionSG.id}"] # SSH just from the bastion
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["${aws_instance.Mongo_Slave1.private_ip}","${aws_instance.Mongo_Slave2.private_ip}","${aws_instance.Mongo_Master.private_ip}"] # all traffic just from the bastion
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
    cidr_blocks = ["0.0.0.0/0"] # All ssh traffic allow
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
data "template_file" "user_data_bastion" {
  template = "${file("./scripts/bastion_userdata.sh")}"

  vars {
    EIP_ID = "${aws_eip.eip_bastion.id}"
  }
}

resource "aws_eip" "eip_bastion" {
  vpc = true
}

resource "aws_launch_configuration" "Bastion_LC" {
  name                        = "bastion_LC"
  image_id                    = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.BastionSG.id}"]
  associate_public_ip_address = false

  #user_data       = "${file("./scripts/bastion_userdata.sh")}"
  user_data  = "${data.template_file.user_data_bastion.rendered}"
  depends_on = ["aws_eip.eip_bastion"]
}

resource "aws_autoscaling_group" "Bastion" {
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = ["${aws_subnet.us_east_1a_public.id}", "${aws_subnet.us_east_1b_public.id}", "${aws_subnet.us_east_1c_public.id}"]
  launch_configuration = "${aws_launch_configuration.Bastion_LC.name}"

  tag {
    key                 = "Name"
    value               = "Bastion"
    propagate_at_launch = true
  }
}

#output
output "Mongo1a_private_ip" {
  value = "${aws_instance.Mongo_Master.private_ip}"
}

output "Mongo1b_private_ip" {
  value = "${aws_instance.Mongo_Slave1.private_ip}"
}

output "Mongo1c_private_ip" {
  value = "${aws_instance.Mongo_Slave2.private_ip}"
}
