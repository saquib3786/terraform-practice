resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

module "myapp-subnet" {
  source = "./modules/subnets"
  vpc_id = aws_vpc.myapp-vpc.id
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  route_table_id = aws_vpc.myapp-vpc.main_route_table_id
}

module "myapp-webserver" {
  source = "./modules/webservers"
  vpc_id = aws_vpc.myapp-vpc.id
  my_ip = var.my_ip
  env_prefix = var.env_prefix
  image_name = var.image_name
  local_public_key_location = var.local_public_key_location
  private_key_location = var.private_key_location
  instance_type = var.instance_type
  subnet_id = module.myapp-subnet.subnet.id
  avail_zone = var.avail_zone

  
}