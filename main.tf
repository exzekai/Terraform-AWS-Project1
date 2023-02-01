provider "aws" {
    region = "us-east-1"
    access_key = "key"
    secret_key = "key"
}
#1 create a vpc
resource "aws_vpc" "t1vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}
#2create internet gateway
resource "aws_internet_gateway" "T1Igw" {
  vpc_id = aws_vpc.t1vpc.id
}
#3 create a route table
resource "aws_route_table" "T1rtable" {
  vpc_id = aws_vpc.t1vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.T1Igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.T1Igw.id
  }

  tags = {
    Name ="Prod"
  }
}
  #4 create a subnet
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.t1vpc.id
  cidr_block = "10.0.1.0/24" 
  availability_zone = "us-east-1a"

  tags = {
    Name = "prodsubnet"
  }
}
#5 assoc subnet with route table
resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.T1rtable.id
}

#6 create security group to allow 22, 80, 443 
resource "aws_security_group" "allowweb" {
  name        = "allow_web_traffic"
  description = "Allow Web traffic on 3 ports"
  vpc_id      = aws_vpc.t1vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
  #7 network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "WbserverNIT1" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allowweb.id]

#   attachment {
#     instance     = aws_instance.test.id
#     device_index = 1
 # }
}

#8 create an elastic IP to NIT1
resource "aws_eip" "eip" {
  vpc                       = true
  network_interface         = aws_network_interface.WbserverNIT1.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.T1Igw]
}

#9 create an ubuntu server and install/enable apache2
resource "aws_instance" "ubuntuserver" {
    ami = "ami-00874d747dde814fa"
    instance_type =  "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "T1"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.WbserverNIT1.id
    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'My Very first web server on AWS with Terraform > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }
}
