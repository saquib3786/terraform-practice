output "aws_ami_id" {
    value = module.myapp-webserver.instance.ami
}
output "public_ip" {
   value = module.myapp-webserver.instance.public_ip
  
}
