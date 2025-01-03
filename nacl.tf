# Network ACL for Private Subnets
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_id

  # Allow all local requests within VPC
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Docker Registry IPs
  # registry-1.docker.io
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "54.0.0.0/8"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "54.0.0.0/8"
    from_port  = 443
    to_port    = 443
  }

  # Cloudflare IP ranges
  # https://api.cloudflare.com/client/v4/ips
  # https://www.cloudflare.com/ips/
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "173.245.48.0/20"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 301
    action     = "allow"
    cidr_block = "103.21.244.0/22"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 302
    action     = "allow"
    cidr_block = "103.22.200.0/22"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 303
    action     = "allow"
    cidr_block = "103.31.4.0/22"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 304
    action     = "allow"
    cidr_block = "141.101.64.0/18"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 305
    action     = "allow"
    cidr_block = "108.162.192.0/18"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 306
    action     = "allow"
    cidr_block = "190.93.240.0/20"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 307
    action     = "allow"
    cidr_block = "188.114.96.0/20"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 308
    action     = "allow"
    cidr_block = "197.234.240.0/22"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 309
    action     = "allow"
    cidr_block = "198.41.128.0/17"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 310
    action     = "allow"
    cidr_block = "162.158.0.0/15"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 311
    action     = "allow"
    cidr_block = "104.16.0.0/13"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 312
    action     = "allow"
    cidr_block = "104.24.0.0/14"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 313
    action     = "allow"
    cidr_block = "172.64.0.0/13"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 314
    action     = "allow"
    cidr_block = "131.0.72.0/22"
    from_port  = 1024
    to_port    = 65535
  }

  # Cloudflare egress rules
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "173.245.48.0/20"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 301
    action     = "allow"
    cidr_block = "103.21.244.0/22"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 302
    action     = "allow"
    cidr_block = "103.22.200.0/22"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 303
    action     = "allow"
    cidr_block = "103.31.4.0/22"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 304
    action     = "allow"
    cidr_block = "141.101.64.0/18"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 305
    action     = "allow"
    cidr_block = "108.162.192.0/18"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 306
    action     = "allow"
    cidr_block = "190.93.240.0/20"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 307
    action     = "allow"
    cidr_block = "188.114.96.0/20"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 308
    action     = "allow"
    cidr_block = "197.234.240.0/22"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 309
    action     = "allow"
    cidr_block = "198.41.128.0/17"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 310
    action     = "allow"
    cidr_block = "162.158.0.0/15"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 311
    action     = "allow"
    cidr_block = "104.16.0.0/13"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 312
    action     = "allow"
    cidr_block = "104.24.0.0/14"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 313
    action     = "allow"
    cidr_block = "172.64.0.0/13"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 314
    action     = "allow"
    cidr_block = "131.0.72.0/22"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name = "private-subnet-nacl"
  }
}
