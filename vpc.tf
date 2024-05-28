resource "aws_vpc" "this" {
  cidr_block       = var.vpc.cidr
  instance_tenancy = "default"
  tags             = merge({ Name = var.vpc.name }, var.vpc.tags)
}

resource "aws_subnet" "this" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = "${var.region}${each.value.az}"
  tags              = merge({ Name = each.value.name }, each.value.tags)
}

resource "aws_internet_gateway" "this" {
  count  = local.deploy_igw == true ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = { Name = "igw-${data.aws_default_tags.this.tags.Project}" }
}

resource "aws_route_table" "this" {
  for_each = local.routing_tables_to_create
  #   for_each = toset(local.rts)
  vpc_id = aws_vpc.this.id

}

resource "aws_route" "this" {
  for_each               = merge(local.default_routing_public_subnets, local.default_routing_private_subnets)
  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = try(each.value.gateway_id, null)
  nat_gateway_id         = try(each.value.nat_gateway_id, null)
  lifecycle {
    precondition {
      condition     = length({ for k, v in var.subnets : k => v if v.type == "private" && v.internet == true }) > 0 ? var.natgw.deploy == false ? false : true : true
      error_message = "You are trying to deploy at least one private network with internet=true but without natgw.deploy=true."
    }
  }
}

resource "aws_route_table_association" "this" {
  for_each       = var.subnets
  subnet_id      = aws_subnet.this["${each.key}"].id
  route_table_id = each.value.type == "public" ? aws_route_table.this["public"].id : aws_route_table.this["${each.key}"].id
}

locals {
  #rts        = concat(distinct([for k, v in var.subnets : v.type if v.type == "public"]), values(local.public_to_private_subnet_map)) //Construct all the routing tables that needs to be created.
  deploy_igw = length({ for k, v in var.subnets : k => v if v.type == "public" }) > 0 || var.vpc.deploy_igw == true ? true : false
}

# ###--------------------------------------AWS NAT Gateway----------------------------------------------
resource "aws_eip" "this" {
  for_each = var.natgw.deploy == true ? toset(var.natgw.subnets) : []
}

resource "aws_nat_gateway" "this" {
  for_each      = var.natgw.deploy == true ? toset(var.natgw.subnets) : []
  allocation_id = aws_eip.this["${each.key}"].id
  subnet_id     = aws_subnet.this["${each.key}"].id

  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_internet_gateway.this]
}




locals {

  default_routing_public_subnets = {

    public = {
      type                   = "public"
      route_table_id         = "${aws_route_table.this["public"].id}"
      destination_cidr_block = "0.0.0.0/0"
      gateway_id             = "${aws_internet_gateway.this[0].id}"
    }

  }

}

locals {
  az_to_private_subnet_with_internet = { for k, v in var.subnets : "${var.region}${v.az}" => k if v.type == "private" && v.internet == true }
  public_subnet_to_az                = { for k, v in var.subnets : "${var.region}${v.az}" => k if v.type == "public" }
  #public_to_private_subnet_map = var.natgw.deploy==true && length(local.az_to_private_subnet_with_internet)>0 ? { for k, v in local.az_to_private_subnet_with_internet : v => local.public_subnet_to_az["${k}"] }: {}
  #nat_gateways                 =  var.natgw.deploy == true ? [for k, v in var.natgw.subnets : aws_nat_gateway.this["${v}"].id] : null
}

locals {
  public_subnets                 = { for k, v in var.subnets : k => "${var.region}${v.az}" if v.type == "public" }
  nat_gw_public_subnets          = { for k, v in var.natgw.subnets : v => local.public_subnets["${v}"] }
  inverted_nat_gw_public_subnets = { for k, v in local.nat_gw_public_subnets : v => k }
  private_to_public_subnet_map   = { for k, v in local.az_to_private_subnet_with_internet : v => try(local.inverted_nat_gw_public_subnets["${k}"], null) }
}



locals {
  default_routing_private_subnets = { for k, v in local.private_to_public_subnet_map : k => { type = "private",
    route_table_id         = "${aws_route_table.this["${k}"].id}",
    destination_cidr_block = "0.0.0.0/0",
    nat_gateway_id         = var.natgw.deploy == true ? try(aws_nat_gateway.this["${v}"].id, aws_nat_gateway.this["${var.natgw.subnets[0]}"].id) : null
    }
  }
}

locals {
  routing_tables_to_create = merge({ public = [for k, v in var.subnets : v if v.type == "public"][0] }, { for k, v in var.subnets : k => v if v.type == "private" })
}
