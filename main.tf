# VPC Configuration
# Creates a secure VPC with public and private subnets across two availability zones
module "vpc" {
  source   = "shamimice03/vpc/aws"
  version  = "1.2.2"
  create   = true
  vpc_name = "secure-env-vpc"
  cidr     = "10.5.0.0/16"

  azs                 = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnet_cidr  = ["10.5.0.0/20", "10.5.16.0/20"]
  private_subnet_cidr = ["10.5.32.0/20", "10.5.48.0/20"]

  enable_dns_hostnames      = true
  enable_dns_support        = true
  enable_single_nat_gateway = false

  tags = {
    Name = "secure-env-vpc"
  }
}

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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS to VPC CIDR"
  }

  tags = {
    Name = "vpc-endpoints-sg"
  }
}

# VPC Endpoints Configuration
# Sets up Gateway endpoints for S3 and DynamoDB access, plus SSM endpoints
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.17.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = [module.vpc.private_route_table_id]
      tags            = { Name = "s3-gateway-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = [module.vpc.private_route_table_id]
      tags            = { Name = "dynamodb-gateway-vpc-endpoint" }
    }

    # Interface endpoints for Session Manager (these need security groups)
    ssm = {
      service             = "ssm"
      subnet_ids          = module.vpc.private_subnet_id
      private_dns_enabled = true
      tags                = { Name = "ssm-vpc-endpoint" }
    },
    ssmmessages = {
      service             = "ssmmessages"
      subnet_ids          = module.vpc.private_subnet_id
      private_dns_enabled = true
      tags                = { Name = "ssmmessages-vpc-endpoint" }
    },
    ec2messages = {
      service             = "ec2messages"
      subnet_ids          = module.vpc.private_subnet_id
      private_dns_enabled = true
      tags                = { Name = "ec2messages-vpc-endpoint" }
    }
  }


}

# IAM Role for Session Manager Access
# Creates a role that allows EC2 instances to communicate with Systems Manager
resource "aws_iam_role" "session_manager_role" {
  name = "session-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "session-manager-role"
  }
}

# Attach AWS managed policy for Session Manager functionality
resource "aws_iam_role_policy_attachment" "session_manager_policy" {
  role       = aws_iam_role.session_manager_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile to attach the role to EC2 instances
resource "aws_iam_instance_profile" "session_manager_profile" {
  name = "session-manager-profile"
  role = aws_iam_role.session_manager_role.name
}

# Security Group for Private EC2 Instances
resource "aws_security_group" "private_instance" {
  name_prefix = "private-instance-sg"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS to internet via NAT Gateway"
  }

  tags = {
    Name = "private-instance-sg"
  }
}

# Network ACL for Private Subnets
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_id

  # Allow outbound HTTPS to VPC endpoints
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Allow return traffic for VPC endpoint requests
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = module.vpc.vpc_cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # Allow outbound HTTPS to internet via NAT Gateway
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow return traffic for internet requests
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "private-subnet-nacl"
  }
}

# EC2 Instance in Private Subnet with Session Manager Access
resource "aws_instance" "private" {
  ami           = "ami-0ab02459752898a60" # Amazon Linux 2023 AMI
  instance_type = "t3.micro"

  subnet_id                   = module.vpc.private_subnet_id[0]
  vpc_security_group_ids      = [aws_security_group.private_instance.id]
  associate_public_ip_address = false

  # Attach the IAM role via instance profile for Session Manager access
  iam_instance_profile = aws_iam_instance_profile.session_manager_profile.name

  # Installation and configuration script
  user_data = <<-EOF
              #!/bin/bash
              # Update the system packages
              dnf update -y

              # Install Docker package
              dnf install -y docker

              # Enable and start Docker service
              systemctl enable docker
              systemctl start docker

              # Add ec2-user to docker group for non-root access
              usermod -a -G docker ec2-user
              EOF

  # Enable IMDSv2 for enhanced metadata security
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Enable EBS encryption for data security
  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "private-instance"
  }
}

# Output important information for reference
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnet_id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.private.private_ip
}