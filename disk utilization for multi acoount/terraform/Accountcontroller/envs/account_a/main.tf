module "oam_sink" {
  source = "../../modules/oam_sink"

  allowed_account_id            = [var.account_b_id]
  additional_source_account_ids = var.additional_source_account_ids
  target_instance_id            = var.target_instance_id
  region                        = var.region
  notification_email            = var.notification_email
}

