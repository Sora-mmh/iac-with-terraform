provider "aws" {
    region = "eu-north-1"
}

variable "subnet_cidr_block" {
  description = "subnet cidr block"
  default = "10.0.10.0/24"
  type = string

}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}

variable "environment" {
  description = "deployment environment"
}

resource "aws_vpc" "development-vpc" { 
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: var.environment,
        vpc_env: "dev"
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = "eu-north-1a"
    tags = {
        Name: "subnet-1-dev"
    }
}

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


