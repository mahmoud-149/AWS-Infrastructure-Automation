module "Network" {
    source = "./modules/network"
    vpc_cidr = var.cidr
    subnet_cidr = var.subnet_cidr
    my_ipv4_public = var.my_ipv4_public
}

module "Compute" {
    source = "./modules/compute"
    ami_id = var.ami_id
    Ec2_type = var.Ec2_type
    key_pair_name = var.key_pair_name
    vpc_id = module.Network.vpc_id
    subnet_id = module.Network.subnet_id
    security_group_id = module.Network.security_group_id
}
