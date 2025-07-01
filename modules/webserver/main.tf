### Use the default security group
resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id
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
        values = [var.image_name] #"amzn2-ami-kernel-*-x86_64-gp2"
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


### Create aws key pair
resource "aws_key_pair" "iac-server-tf" {
    key_name = "iac-server-tf-2"
    public_key = file(var.public_key_location) #var.public_key
}



### Create EC2 instance
resource "aws_instance" "montapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id #module.montapp-subnet.subnet.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id] #[var.default_sg_id] #[aws_default_security_group.default-sg.id]
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
    user_data = file("${path.module}/entry-script.sh")
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