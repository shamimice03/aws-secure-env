# VPC Configuration
# Creates a secure VPC with public and private subnets across two availability zones
module "vpc" {
  source   = "shamimice03/vpc/aws"
  version  = "1.2.3"
  create   = true
  vpc_name = "secure-env-vpc"
  cidr     = "10.5.0.0/16"

  azs                 = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnet_cidr  = ["10.5.0.0/20", "10.5.16.0/20"]
  private_subnet_cidr = ["10.5.32.0/20", "10.5.48.0/20"]

  enable_dns_hostnames      = true
  enable_dns_support        = true
  enable_single_nat_gateway = true

  tags = {
    Name = "secure-env-vpc"
  }
}

# VPC Endpoints Configuration
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.17.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]


  endpoints = {
    # S3 Gateway endpoint
    s3_gateway = {
      create          = true
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = [module.vpc.private_route_table_id]
      tags            = { Name = "s3-gateway-vpc-endpoint" }
    },

    # S3 Interface endpoint
    s3_interface = {
      create              = true
      service             = "s3"
      subnet_ids          = module.vpc.private_subnet_id
      private_dns_enabled = true

      # Required 
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
      tags = { Name = "s3-interface-vpc-endpoint" }
    },

    # Interface endpoints for Session Manager (these need security groups)
    ssm = {
      create              = true
      service             = "ssm"
      subnet_ids          = module.vpc.private_subnet_id
      private_dns_enabled = true
      tags                = { Name = "ssm-vpc-endpoint" }
    },
    ssmmessages = {
      create              = true
      service             = "ssmmessages"
      subnet_ids          = module.vpc.private_subnet_id
      private_dns_enabled = true
      tags                = { Name = "ssmmessages-vpc-endpoint" }
    },
    ec2messages = {
      create              = true
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





