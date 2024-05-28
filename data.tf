data "aws_availability_zones" "this" {
  state = "available"
}

data "aws_default_tags" "this" {}