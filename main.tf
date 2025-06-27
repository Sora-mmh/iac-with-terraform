provider "aws" {
    region = "eu-north-1"
}


# variable cidr_blocks {
#     description = "cidr blocks and name tags for vpc subnets"
#     type = list(object({
#         cidr_block = string
#         name = string
#     }))
# }
# variable "environment" {
#   description = "deployment environment"
# }
# variable "subnet_cidr_block" {
#   description = "subnet cidr block"
#   default = "10.0.10.0/24"
#   type = string
# }
# variable "vpc_cidr_block" {
#   description = "vpc cidr block"
# }

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
# variable public_key {}
variable public_key_location {}

resource "aws_vpc" "montapp-vpc" { 
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "montapp-subnet-1" {
    vpc_id = aws_vpc.montapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

### Create a new route table
# resource "aws_route_table" "montapp-route-table" {
#     vpc_id = aws_vpc.montapp-vpc.id
#     route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.montapp-igw.id
#     }
#     tags = {
#         Name: "${var.env_prefix}-rtb"
#     }
# }

### Not necessarily declared before resource rtb
resource "aws_internet_gateway" "montapp-igw"{
    vpc_id = aws_vpc.montapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

### Use the default route table (created when creating the resourcce vpc)
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.montapp-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.montapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}


### Use the default security group
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.montapp-vpc.id
    ### handles incoming rules (ex : SSH into EC2, access from browser)
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [var.my_ip]

    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]

    }

    ### handles outgoing rules (ex : installations, fetch docker images)
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

### Especially to validate what we are getting when calling data
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image
}

### Create aws key pair
resource "aws_key_pair" "iac-server-tf" {
    key_name = "iac-server-tf"
    public_key = file(var.public_key_location) #var.public_key
}

### Outputs EC2 instance public IP
output "ec2_public_ip" {
    value = aws_instance.montapp-server.public_ip
}

### Create EC2 instance
resource "aws_instance" "montapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.montapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.iac-server-tf.key_name #"iac-server"

    # user_data = <<EOF
    #                 #!/bin/bash
    #                 sudo yum update -y && sudo yum install -y docker
    #                 sudo systemctl start docker
    #                 sudo usermod -aG docker ec2-user
    #                 docker run -p 8080:80 nginx
    #             EOF

    ### .sh scripts
    user_data = file("entry-script.sh")
    user_data_replace_on_change = true

    tags = {
        Name: "${var.env_prefix}-server"
    }
}

### Create a new securit group (not using the default one created when creating the vpc)
# resource "aws_security_group" "montapp-sg" {
#     name = "montapp-sg"
#     vpc_id = aws_vpc.montapp-vpc.id
#     ### handles incoming rules (ex : SSH into EC2, access from browser)
#     ingress {
#         from_port = 22
#         to_port = 22
#         protocol = "TCP"
#         cidr_blocks = [var.my_ip]

#     }
#     ingress {
#         from_port = 8080
#         to_port = 8080
#         protocol = "TCP"
#         cidr_blocks = ["0.0.0.0/0"]

#     }

#     ### handles outgoing rules (ex : installations, fetch docker images)
#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#         prefix_list_ids = []
#     }

#     tags = {
#         Name: "${var.env_prefix}-sg"
#     }

# }







### association between a route table and a subnet (if rtb is created apart from vpc, otherwise all subnets are associated with the main rtb)
# resource "aws_route_table_association" "a-rtb_subnet" {
#     subnet_id = aws_subnet.montapp-subnet-1.id
#     route_table_id = aws_route_table.montapp-route-table.id
# }



### Create a data instance for a created resource to use it for creating other resources
# data "aws_vpc" "existing_vpc" {
#     default = true
# }

# resource "aws_subnet" "dev-subnet-2" {
#     vpc_id = data.aws_vpc.existing_vpc.id
#     cidr_block = "172.31.96.0/20"
#     availability_zone = "eu-north-1a"
#     tags = {
#         Name: "subnet-2-default"
#     }
# }

### Print output of attributes of created resources
# output "dev-vpc-id" {
#     value = aws_vpc.development-vpc.id
# }

# output "dev-subnet-id" {
#     value = aws_subnet.dev-subnet-1.id
# }


