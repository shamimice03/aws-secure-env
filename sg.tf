# Security Group for VPC Endpoints
# Controls access to AWS services through VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "vpc-endpoints-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow HTTPS from VPC CIDR"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS to VPC CIDR"
  }

  tags = {
    Name = "vpc-endpoints-sg"
  }
}

# Security Group for Private EC2 Instances
resource "aws_security_group" "private_instance" {
  name_prefix = "private-instance-sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow HTTPS to internet via NAT Gateway"
  }

  tags = {
    Name = "private-instance-sg"
  }
}
