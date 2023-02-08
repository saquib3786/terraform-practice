resource "aws_security_group" "dev-sg" {
    name = "myapp-sg"
    vpc_id = var.vpc_id

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
      values = [var.image_name]
    }
}

resource "aws_key_pair" "dev-key1" {
    key_name = "dev-key1"
    public_key = "${file(var.local_public_key_location)}"
  
}
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  key_name = aws_key_pair.dev-key1.key_name

  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.dev-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true 
  user_data = file("userdata.sh")

   provisioner "remote-exec" {
    inline = [
      "mkdir file1"
    ]
   
   }  

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }


  tags = {
    "name" = "${var.env_prefix}-server"
  }

}
