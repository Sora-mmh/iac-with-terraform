resource "aws_subnet" "montapp-subnet-1" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

### Create a new route table
# resource "aws_route_table" "montapp-route-table" {
#     vpc_id = var.vpc_id
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
    vpc_id = var.vpc_id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

### Use the default route table (created when creating the resourcce vpc)
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = var.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.montapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-main-rtb"
    }
}

# resource "aws_subnet" "dev-subnet-2" {
#     vpc_id = data.aws_vpc.existing_vpc.id
#     cidr_block = "172.31.96.0/20"
#     availability_zone = "eu-north-1a"
#     tags = {
#         Name: "subnet-2-default"
#     }
# }

### association between a route table and a subnet (if rtb is created apart from vpc, otherwise all subnets are associated with the main rtb)
# resource "aws_route_table_association" "a-rtb_subnet" {
#     subnet_id = aws_subnet.montapp-subnet-1.id
#     route_table_id = aws_route_table.montapp-route-table.id
# }