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
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "vpc_id" {
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


