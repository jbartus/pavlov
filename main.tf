terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.42"
    }
  }

  required_version = ">= 0.15.4"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

data "aws_ssm_parameter" "latest-amzn2-ami" {
   name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_launch_template" "pavlov-lt" {
  image_id = data.aws_ssm_parameter.latest-amzn2-ami.value
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
    }
  }
  instance_market_options {
    market_type = "spot"
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.pavlov-profile.name
  }
  instance_type          = "m6i.large"
  key_name               = "ohio-pavlov"
  user_data              = filebase64("userdata.sh")
  vpc_security_group_ids = [aws_security_group.pavlov-sg.id]
}

resource "aws_autoscaling_group" "pavlov-asg" {
  availability_zones = ["us-east-2a", "us-east-2b"]
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.pavlov-lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_schedule" "gametime" {
  scheduled_action_name  = "on-at-3p"
  desired_capacity       = 1
  min_size               = 1
  max_size               = 1
  recurrence             = "0 19 * * *"
  autoscaling_group_name = aws_autoscaling_group.pavlov-asg.name
}

resource "aws_autoscaling_schedule" "bedtime" {
  scheduled_action_name  = "off-at-3a"
  desired_capacity       = 0
  recurrence             = "0 7 * * *"
  autoscaling_group_name = aws_autoscaling_group.pavlov-asg.name
}

resource "aws_iam_policy" "pavlov-policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:us-east-2:601049323275:secret:github-pat-for-docker-pull-mIuSsJ"
      },
    ]
  })
}

resource "aws_iam_role" "pavlov-role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.pavlov-policy.arn]
}

resource "aws_iam_instance_profile" "pavlov-profile" {
  role = aws_iam_role.pavlov-role.name
}

resource "aws_security_group" "pavlov-sg" {
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 7777
    to_port          = 7777
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 8177
    to_port          = 8177
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
