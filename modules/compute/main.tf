resource "aws_instance" "terAns" {
    ami = var.ami_id
    key_name = var.key_pair_name
    instance_type = var.Ec2_type    
    vpc_security_group_ids = [var.security_group_id]
    subnet_id = var.subnet_id
    tags = {
    Name = "terraform-ansible-lab"
  }
    }

