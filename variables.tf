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
variable image_name {}