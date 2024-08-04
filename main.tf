
# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id     #attach it to VPC 
  tags = {
    Name = "my-internet-gateway"
  }
}

# Create a Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "main-route-table"
  }
}

# Associate the Route Table with the VPC
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main.id
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1b"  # Replace with your preferred availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Define a Security Group for the EC2 instance
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh"
  }
}
//optional
/* # Create a key pair for SSH access (Note: replace the key name with your own key name)
resource "aws_key_pair" "deployer" {
  key_name   = "my-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")  # Replace with your public key path
} */

# Define the EC2 instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id  #get AMI ID from data sources
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id      # get existing key pair 
  key_name       = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id] 

  tags = {
    Name = "web-instance"
  }
}

# Fetch the latest Amazon Linux 2 AMI ID
data "aws_ami" "ubuntu" {
  filter {
    name   = "name"
    values = ["ubuntu-*-20.04-*"]  # Example for Ubuntu 20.04 x86_64 AMI
  }
  most_recent = true
  owners      = ["099720109477"]  # Canonical's AWS account ID
}

data "aws_key_pair" "existing_key" {
  key_name = "TF-key-pair"  # Replace with your key name
}