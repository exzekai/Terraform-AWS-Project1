# Terraform-AWS-Project 1
This is the terraform code which can be used to create a web server in AWS.
The code will create -
- VPC
- Internet Gateway
- Custom Route Table
- Subnet
- Security Group to allow 22, 80, 443 port traffic
- Network Interface associated with the subnet
- Elastic IP to Network Interface
- Ec2 Ubuntu instance with Apache2 installed
