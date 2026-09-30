variable "oam_sink_name" {
  type    = string
  default = "CentralMonitoringOAM"
}
variable "allowed_account_id" {
  type        = list(string)
  description = "Source account IDs allowed to create OAM links and publish metrics"
}

variable "additional_source_account_ids" {
  type        = list(string)
  description = "Optional additional source accounts to include in hub monitoring"
  default     = []
}
variable "region" {
  type        = string
  description = "AWS Region shared by the hub and source account"
}

variable "notification_email" {
  type        = string
  description = "Optional email address subscribed to disk alarm notifications"
  default     = null
  nullable    = true
}

variable "target_instance_id" {
  type = string
}

