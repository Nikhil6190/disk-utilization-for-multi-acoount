# 1. Create oAM sink
resource "aws_oam_sink" "oam" {
  name = var.oam_sink_name
}
# 2.Sink access policy

resource "aws_oam_sink_policy" "oam_sink_policy" {
  sink_identifier = aws_oam_sink.oam.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.source_account_ids }
      Action    = ["oam:CreateLink", "oam:UpdateLink"]
      Resource  = "*"
      Condition = {
        "ForAllValues:StringEquals" = {
          "oam:ResourceTypes" = ["AWS::CloudWatch::Metric"]
        }
      }
    }]
  })
}

locals {
  source_account_ids = distinct(concat(var.allowed_account_id, var.additional_source_account_ids))
}

# 3.SNS Topic for Disk Spaace warnings
resource "aws_sns_topic" "disk_alert" {
  name = "low-space-alerts"
}

resource "aws_sns_topic_subscription" "disk_alert_email" {
  count = var.notification_email == null || trimspace(var.notification_email) == "" ? 0 : 1

  topic_arn = aws_sns_topic.disk_alert.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# 4. Centralized Cloudwatch Alarm
resource "aws_cloudwatch_metric_alarm" "disk_usage_high" {
  alarm_name          = "low-disk-space"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  alarm_description   = "Triggers when disk usage exceeds 80%"
  alarm_actions       = [aws_sns_topic.disk_alert.arn]

  metric_query {
    id          = "disk"
    account_id  = var.allowed_account_id[0]
    return_data = true

    metric {
      metric_name = "disk_used_percent"
      namespace   = "CWAgent"
      period      = 300
      stat        = "Average"

      dimensions = {
        InstanceId = var.target_instance_id
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "fleet_disk_usage_high" {
  for_each = toset(local.source_account_ids)

  alarm_name          = "disk-usage-high-${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  alarm_description   = "Triggers when any monitored instance in source account ${each.value} reaches 80% disk usage"
  alarm_actions       = [aws_sns_topic.disk_alert.arn]

  metric_query {
    id          = "disk"
    account_id  = each.value
    expression  = "SELECT MAX(disk_used_percent) FROM SCHEMA(\"CWAgent\", InstanceId)"
    return_data = true
    period      = 300
  }
}

resource "aws_cloudwatch_dashboard" "disk_usage" {
  dashboard_name = "central-disk-usage"
  dashboard_body = jsonencode({
    widgets = [{
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [[
          "CWAgent",
          "disk_used_percent",
          "InstanceId",
          var.target_instance_id,
          {
            accountId = var.allowed_account_id[0]
            region    = var.region
            stat      = "Average"
            period    = 300
          }
        ]]
        view    = "timeSeries"
        stacked = false
        region  = var.region
        title   = "Disk utilization - Account B"
        yAxis = {
          left = {
            min = 0
            max = 100
          }
        }
      }
    }]
  })
}

resource "aws_cloudwatch_dashboard" "fleet_disk_usage" {
  dashboard_name = "central-disk-usage-fleet"
  dashboard_body = jsonencode({
    widgets = [
      for index, account_id in local.source_account_ids : {
        type   = "metric"
        x      = 0
        y      = index * 6
        width  = 12
        height = 6
        properties = {
          metrics = [[{
            expression = "SELECT MAX(disk_used_percent) FROM SCHEMA(\"CWAgent\", InstanceId) GROUP BY InstanceId"
            id         = "disk_${index}"
            accountId  = account_id
            period     = 300
          }]]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Disk utilization - Account ${account_id}"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      }
    ]
  })
}

    