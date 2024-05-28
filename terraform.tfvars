region             = "eu-west-1"
availability_zones = ["a,b,c"]

vpc = {
  name       = "VPC-Matrix"
  cidr       = "10.10.0.0/16"
  deploy_igw = true
}

natgw = {
  deploy  = false
  subnets = ["pub_01"]
}


subnets = {

  priv_01 = {
    name     = "matrix-private-az-1a"
    type     = "private"
    internet = false
    cidr     = "10.10.2.0/24"
    az       = "a"
  }

  priv_02 = {
    name     = "matrix-private-az-1b"
    type     = "private"
    internet = false
    cidr     = "10.10.4.0/24"
    az       = "b"
  }

  priv_03 = {
    name     = "matrix-private-az-1c"
    type     = "private"
    internet = false
    cidr     = "10.10.6.0/24"
    az       = "c"
  }

  pub_01 = {
    name = "matrix-public-az-1a"
    type = "public"
    cidr = "10.10.1.0/24"
    az   = "a"
  }

  pub_02 = {
    name = "matrix-public-az-1b"
    type = "public"
    cidr = "10.10.3.0/24"
    az   = "b"
  }

  pub_03 = {
    name = "matrix-public-az-1c"
    type = "public"
    cidr = "10.10.5.0/24"
    az   = "c"
  }

}