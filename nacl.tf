variable "network_rules" {
  description = "NACL rules configuration for all categories"
  type = map(object({
    create     = bool
    name       = string
    rule_start = number
    cidrs      = list(string)
    ingress = object({
      protocol  = string
      from_port = number
      to_port   = number
    })
    egress = object({
      protocol  = string
      from_port = number
      to_port   = number
    })
  }))

  default = {
    vpc = {
      create     = true
      name       = "VPC Internal"
      rule_start = 100
      cidrs      = ["10.0.0.0/16"] # Will be replaced by VPC CIDR
      ingress = {
        protocol  = "-1"
        from_port = 0
        to_port   = 0
      }
      egress = {
        protocol  = "-1"
        from_port = 0
        to_port   = 0
      }
    }
    docker = {
      create     = false
      name       = "Docker Registry"
      rule_start = 200
      cidrs      = ["54.0.0.0/8"]
      ingress = {
        protocol  = "tcp"
        from_port = 1024
        to_port   = 65535
      }
      egress = {
        protocol  = "tcp"
        from_port = 443
        to_port   = 443
      }
    }
    cloudflare = {
      create     = false
      name       = "Cloudflare"
      rule_start = 300
      cidrs = [
        "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22",
        "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18",
        "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22",
        "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
        "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22"
      ]
      ingress = {
        protocol  = "tcp"
        from_port = 1024
        to_port   = 65535
      }
      egress = {
        protocol  = "tcp"
        from_port = 443
        to_port   = 443
      }
    }
    s3_prefix_list = {
      create     = false
      name       = "S3 Endpoints"
      rule_start = 250
      cidrs = [
        "3.5.152.0/21", "52.219.0.0/20", "52.219.136.0/22",
        "52.219.150.0/23", "52.219.152.0/22", "52.219.16.0/22",
        "52.219.162.0/23", "52.219.172.0/22", "52.219.195.0/24",
        "52.219.196.0/22", "52.219.20.0/24", "52.219.200.0/23",
        "52.219.68.0/22"
      ]
      ingress = {
        protocol  = "tcp"
        from_port = 1024
        to_port   = 65535
      }
      egress = {
        protocol  = "tcp"
        from_port = 443
        to_port   = 443
      }
    }
  }
}

locals {
  # Filter enabled rules
  enabled_rules = {
    for category, config in var.network_rules :
    category => config
    if config.create
  }
}

# Network ACL for Private Subnets
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_id

  # Generate all ingress rules for enabled categories
  dynamic "ingress" {
    for_each = merge([
      for category, config in local.enabled_rules : {
        for idx, cidr in config.cidrs : "${category}-${idx}" => {
          rule_no    = config.rule_start + idx
          protocol   = config.ingress.protocol
          cidr_block = category == "vpc" ? module.vpc.vpc_cidr_block : cidr
          from_port  = config.ingress.from_port
          to_port    = config.ingress.to_port
        }
      }
    ]...)

    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = "allow"
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  # Generate all egress rules for enabled categories
  dynamic "egress" {
    for_each = merge([
      for category, config in local.enabled_rules : {
        for idx, cidr in config.cidrs : "${category}-${idx}" => {
          rule_no    = config.rule_start + idx
          protocol   = config.egress.protocol
          cidr_block = category == "vpc" ? module.vpc.vpc_cidr_block : cidr
          from_port  = config.egress.from_port
          to_port    = config.egress.to_port
        }
      }
    ]...)

    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = "allow"
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

  tags = {
    Name = "private-subnet-nacl"
  }
}
