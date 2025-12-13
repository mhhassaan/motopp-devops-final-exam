terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

#VPC
resource "aws_vpc" "motopp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { 
    Name = "motopp-vpc" 
    }
}

#Subnet
resource "aws_subnet" "motopp_subnet" {
  vpc_id                  = aws_vpc.motopp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { 
    Name = "motopp-public-subnet" 
    }
}

#gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.motopp_vpc.id
  tags = { 
    Name = "motopp-igw"
     }
}

#route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.motopp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
     Name = "motopp-public-rt"
      }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.motopp_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#Security Groups 
resource "aws_security_group" "allow_traffic" {
  name        = "motopp-sg"
  description = "Allow SSH, HTTP, and App ports"
  vpc_id      = aws_vpc.motopp_vpc.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Flask App Port (if running directly)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes NodePort Range (for later steps)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Internet Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Compute (EC2 for Kubernetes/App) 
# Using a data source to get the latest Ubuntu 22.04 AMI dynamically
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "k8s_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium" # Minimum recommended for K8s/Minikube
  subnet_id     = aws_subnet.motopp_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_traffic.id]
  
  # IMPORTANT: Make sure you have this key pair created in AWS Console first!
  key_name      = "motopp-lab-exam" # Change this to your actual AWS Key Pair name

  tags = {
    Name = "Motopp-K8s-Node"
  }
}

# 4. Persistence (S3 Bucket) 
# Random ID to ensure bucket name is unique globally
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "motopp_storage" {
  bucket = "motopp-assets-${random_id.bucket_id.hex}"
  force_destroy = true # Allows deleting bucket even if it has files (for lab cleanup)
  
  tags = {
    Name        = "Motopp Assets"
    Environment = "Lab"
  }
}

# 5. Outputs [cite: 40]
output "ec2_public_ip" {
  value = aws_instance.k8s_node.public_ip
  description = "The public IP of the web server/K8s node"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.motopp_storage.bucket
  description = "Name of the created S3 bucket"
}