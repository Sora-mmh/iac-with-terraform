### Especially to validate what we are getting when calling data
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image
}

### Outputs EC2 instance public IP
output "ec2_public_ip" {
    value = aws_instance.montapp-server.public_ip
}

### Print output of attributes of created resources
# output "dev-vpc-id" {
#     value = aws_vpc.development-vpc.id
# }

# output "dev-subnet-id" {
#     value = aws_subnet.dev-subnet-1.id
# }