data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Ubuntu 24.04 LTS più recente, pubblicata da Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  prefix = "tfcourse-${var.student}"
  tags = {
    course = "dvo05"
    owner  = var.student
  }
  azs = data.aws_availability_zones.available.names
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "vpc-${local.prefix}" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "igw-${local.prefix}" })
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = local.azs[index(sort(keys(var.subnets)), each.key) % length(local.azs)]
  map_public_ip_on_launch = each.key == "web"
  tags                    = merge(local.tags, { Name = "snet-${each.key}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, { Name = "rt-public-${local.prefix}" })
}

resource "aws_route_table_association" "web" {
  subnet_id      = aws_subnet.this["web"].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "${local.prefix}-web" # i nomi non possono iniziare con "sg-"
  description = "Web: solo le porte elencate in allowed_ports"
  vpc_id      = aws_vpc.main.id
  tags        = local.tags

  dynamic "ingress" {
    for_each = var.allowed_ports

    content {
      description = "allow-${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "uscita libera"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "web" {
  key_name   = "key-${local.prefix}"
  public_key = file(pathexpand(var.ssh_public_key_path))
  tags       = local.tags
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.this["web"].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.web.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/cloud-init.yaml")
  user_data_replace_on_change = true
  tags                        = merge(local.tags, { Name = "vm-web-${var.student}" })

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  depends_on = [aws_route_table_association.web]
}
