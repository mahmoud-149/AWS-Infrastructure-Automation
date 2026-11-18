variable "ami_id" {
#  default = "ami-04005916a1c241ff5"
    type = string
}
variable "subnet_id" {
        type = string
}
variable "security_group_id" {
    type = string
}
variable "vpc_id" {
        type = string
}
variable "Ec2_type" {
 # default = "t3.micro"
        type = string
}
variable "key_pair_name" {
        type = string
}
