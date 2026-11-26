data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "vpc-${var.name_prefix}" })
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[index(sort(keys(var.subnets)), each.key) % length(data.aws_availability_zones.available.names)]
  tags              = merge(var.tags, { Name = "snet-${each.key}" })
}
