variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-south-1"
}
variable "account_b_id" {
  description = "The ID of Account B"
  type        = string
}

variable "additional_source_account_ids" {
  description = "Optional source account IDs beyond Account B"
  type        = list(string)
  default     = []
}
variable "ami_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "target_instance_id" {
  type = string
}

variable "notification_email" {
  description = "Optional email subscription for disk alarm notifications"
  type        = string
  default     = null
  nullable    = true
}


