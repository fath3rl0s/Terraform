# Carlos Enamorado
# Windows Server, DVWA, Ubuntu w/ Kali-Tools Installed

provider "aws" {
  region = "us-east-1"
}

# VPC and Subnet Configuration
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

# Security Group Configuration
resource "aws_security_group" "vulnerability_lab_sg" {
  name        = "vulnerability-lab-sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow RDP access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Windows Server Instance
resource "aws_instance" "windows_server" {
  ami           = "ami-0a8128f5266cdc447" # Update with latest Windows Server AMI ID
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.vulnerability_lab_sg.id]

  key_name = "vuln-cloud-ssh"

  tags = {
    Name = "WindowsServer"
  }
}

# Linux Instance (for DVWA)
resource "aws_instance" "ubuntu_dvwa" {
  ami           = "ami-0a0e5d9c7acc336f1"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.vulnerability_lab_sg.id]

  key_name = "vuln-cloud-ssh"

  tags = {
    Name = "Ubuntu-DVWA"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2 mysql-server php php-mysql git
              sudo systemctl start apache2
              cd /var/www/html
              sudo git clone https://github.com/digininja/DVWA.git dvwa
              cd dvwa
              sudo cp config/config.inc.php.dist config/config.inc.php
              sudo chown -R www-data:www-data /var/www/html/dvwa
              sudo systemctl restart apache2
              EOF
}

# Linux Instance (for Kali tools)
resource "aws_instance" "kali_machine" {
  ami           = "ami-0a0e5d9c7acc336f1" # Public Ubuntu 20.04 LTS AMI in us-east-1
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.vulnerability_lab_sg.id]

  key_name = "vuln-cloud-ssh"

  tags = {
    Name = "KaliMachine"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y kali-linux-default
              EOF
}

# Output instance details
output "windows_server_public_ip" {
  value = aws_instance.windows_server.public_ip
}

output "ubuntu_dvwa_public_ip" {
  value = aws_instance.ubuntu_dvwa.public_ip
}

output "kali_machine_public_ip" {
  value = aws_instance.kali_machine.public_ip
}
