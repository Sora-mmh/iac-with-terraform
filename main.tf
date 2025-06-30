provider "aws" {
    region = "eu-north-1"
}


resource "aws_vpc" "montapp-vpc" { 
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

module "montapp-subnet" {
    source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    avail_zone = var.avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.montapp-vpc.id
    default_route_table_id = aws_vpc.montapp-vpc.default_route_table_id
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


### Create aws key pair
resource "aws_key_pair" "iac-server-tf" {
    key_name = "iac-server-tf"
    public_key = file(var.public_key_location) #var.public_key
}



### Create EC2 instance
resource "aws_instance" "montapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = module.montapp-subnet.subnet.id
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





### Create a data instance for a created resource to use it for creating other resources
# data "aws_vpc" "existing_vpc" {
#     default = true
# }






