resource "aws_vpc" "terraform-ansible-lab" {

    cidr_block = var.vpc_cidr

    tags = {
        Name = "terraform-ansible-lab"
    }
  
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.terraform-ansible-lab.id
  cidr_block = var.subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "terraform-ansible-lab"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terraform-ansible-lab.id

  tags = {
    Name = "terraform-ansible-lab"
  }
}


resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.terraform-ansible-lab.id

  route {
    cidr_block =   "0.0.0.0/0"  #"10.0.1.0/24" 
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "terraform-ansible-lab"
  }
}

resource "aws_route_table_association" "subnetTotable" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "ansTerProject" {
  name        = "ansTerProject"
  description = "Permits inbound SSH on TCP port 22, only from your public IP-Permits inbound HTTP on TCP port 80 for testing the website"
  vpc_id      = aws_vpc.terraform-ansible-lab.id

  tags = {
    Name = "terraform-ansible-lab"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.ansTerProject.id
  cidr_ipv4         = var.my_ipv4_public
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  tags = {
    Name = "terraform-ansible-lab"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.ansTerProject.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = {
    Name = "terraform-ansible-lab"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ansTerProject.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags = {
    Name = "terraform-ansible-lab"
  }
}
