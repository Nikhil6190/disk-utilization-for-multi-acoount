
data "terraform_remote_state" "account_a" {
  backend = "local"
  config = {
    path = "../account_a/terraform.tfstate"
  }
}

module "target_account" {
  source = "../../modules/target_instance"

  ami_id    = var.ami_id
  subnet_id = var.subnet_id
  vpc_id    = var.vpc_id
}

resource "aws_oam_link" "monitoringlink" {
  label_template  = "$AccountName"
  resource_types  = ["AWS::CloudWatch::Metric"]
  sink_identifier = data.terraform_remote_state.account_a.outputs.sink_arn_a
}
