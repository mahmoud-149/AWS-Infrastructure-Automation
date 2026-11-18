terraform {
  backend "s3" {
    bucket = "mybackent-buckettf"
    key    = "terraform-ansible-lab/terraform.tfstate"
    region = "eu-north-1"
    use_lockfile = true
  }
}

