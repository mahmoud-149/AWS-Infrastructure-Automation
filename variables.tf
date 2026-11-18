variable "aws_region" {
    default = "eu-north-1"
  
}
variable "cidr" {
    default = "10.0.0.0/16"
  
}

variable "subnet_cidr" {
    default = "10.0.1.0/24"
}

variable "my_ipv4_public" {
    default = "156.208.225.92test/32"
  
}

variable "key_pair_name" {
    default = "test-1"
  
}

variable "ami_id" {
  default = "ami-04005916a1c241ff5"

}
variable "Ec2_type" {
  default = "t3.micro"

}
