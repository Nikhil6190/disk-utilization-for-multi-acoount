variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-south-1"
}
variable "ami_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  description = "VPC containing the target instance and interface endpoints"
  type = string
}


