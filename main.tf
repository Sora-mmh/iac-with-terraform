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

module "montapp-server" {
    source = "./modules/webserver"
    vpc_id = aws_vpc.montapp-vpc.id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
    instance_type = var.instance_type
    subnet_id = module.montapp-subnet.subnet.id
    avail_zone = var.avail_zone
}




### Create a data instance for a created resource to use it for creating other resources
# data "aws_vpc" "existing_vpc" {
#     default = true
# }






