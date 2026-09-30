
#2. IAM role for SSM and Cloudwatch
resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

#3. Target Ec2 target instance 
resource "aws_instance" "target_instance" {
  ami                  = var.ami_id
  instance_type        = "t2.micro"
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name       = "TargetInstance"
    Monitoring = "Enabled"
  }
}

#4. ssm parameter store for cw agent config 
resource "aws_ssm_parameter" "cw_agent_config" {
  name  = "linux-disk-config"
  type  = "String"
  value = file("${path.module}/../../../../shared/cloudwatch-agent-config.json")
}

#5. SSM: Auto-INsstall cw agent package.check "name" 
resource "aws_ssm_association" "auto_install_cw_agent" {
  name = "AWS-ConfigureAWSPackage"

  targets {
    key    = "tag:Monitoring"
    values = ["Enabled"]
  }

  parameters = {
    action = "Install"
    name   = "AmazonCloudWatchAgent"
  }
}

#6.ssm: Auto-start services with ssm parameter store config
resource "aws_ssm_association" "auto_start_cw_agent" {
  name = "AmazonCloudWatch-ManageAgent"

  targets {
    key    = "tag:Monitoring"
    values = ["Enabled"]
  }

  parameters = {
    action                        = "configure"
    mode                          = "ec2"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = aws_ssm_parameter.cw_agent_config.name
    optionalRestart               = "yes"
  }

  depends_on = [aws_ssm_association.auto_install_cw_agent]
}

#7.ssm:Automated Auto-Healing Disk Cleanup
resource "aws_ssm_document" "disk_cleanup" {
  name          = "DiskCleanup"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Automated Disk Cleanup"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "cleanupDiskSpace"
        inputs = {
          runCommand = [
            "echo 'Starting disk cleanup...'",
            "sudo rm -rf /tmp/*",
            "sudo rm -rf /var/tmp/*",
            "sudo journalctl --vacuum-time=7d",
            "echo 'Disk cleanup completed.'"
          ]
        }
      }
    ]
  })
}

# 8. sg grop for vpc endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

}

# 9. Local services map
locals {
  services = [
    "ssm",
    "ec2messages",
    "ssmmessages",
    "logs",
    "monitoring"
  ]
}

# 10. create interface endpoints 
resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = toset(local.services)

  vpc_id             = var.vpc_id
  service_name       = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids         = [var.subnet_id]

  private_dns_enabled = true
  tags = {
    name = "vpc-endpoint-${each.key}"
  }
}
