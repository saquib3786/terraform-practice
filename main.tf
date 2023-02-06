provider "aws" {
    region = "ap-south-1"
    
}

variable "vpc_cidr_block"{} 
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "local_public_key_location"{}
variable "private_key_location" {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}


resource aws_subnet "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}


resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
      "name" = "${var.env_prefix}-igw"
    }
    
}

resource "aws_route_table" "myapp-route_table" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
      "name" = "${var.env_prefix}-rtb"
    }

}

resource "aws_route" "myapp-route" {
     route_table_id = aws_route_table.myapp-route_table.id
     destination_cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.myapp-igw.id
    
}

resource "aws_route_table_association" "vpc1-routetableAss" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route_table.id
}

resource "aws_security_group" "dev-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    

    tags = {
      "name" = "${var.env_prefix}-sg"
    }
}
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }
}
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
  
}
resource "aws_key_pair" "dev-key1" {
    key_name = "dev-key1"
    public_key = "${file(var.local_public_key_location)}"
  
}
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  key_name = aws_key_pair.dev-key1.key_name

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.dev-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true 
  user_data = file("userdata.sh")
  

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }
  provisioner "remote-exec" {
    inline = [
      "export ENV=dev",
      "mkdir file1"
      
    ]
    
  }
  

  tags = {
    "name" = "${var.env_prefix}-server"
  }

}
output "public_ip" {
   value = aws_instance.myapp-server.public_ip
  
}
