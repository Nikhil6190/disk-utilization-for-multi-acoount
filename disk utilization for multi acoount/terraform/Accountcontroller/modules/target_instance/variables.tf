variable "ami_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "allowed_account_id" {
  description = "AWS account ID allowed to access the OAM sink"
  type        = list(string)
}

variable "target_instance_id" {
  description = "ID of the target EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the target instance resides"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-south-1"
}