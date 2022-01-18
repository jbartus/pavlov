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

resource "aws_launch_template" "pavlov-lt" {
  image_id = "ami-089c6f2e3866f0f14"
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

resource "aws_dynamodb_table" "pavlov-servers" {
  name           = "pavlov-servers"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "logsandddb"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        },
        {
          Action   = ["dynamodb:PutItem", "dynamodb:GetItem"]
          Effect   = "Allow"
          Resource = "${aws_dynamodb_table.pavlov-servers.arn}"
        }
      ]
    })
  }

}

resource "aws_lambda_function" "pavlov-server-post" {
  function_name    = "pavlov-server-post"
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = "pavlov-server-post/pavlov-server-post.zip"
  runtime          = "python3.8"
  handler          = "index.lambda_handler"
  source_code_hash = filebase64sha256("pavlov-server-post/pavlov-server-post.zip")
}

resource "aws_lambda_function" "pavlov-server-get" {
  function_name    = "pavlov-server-get"
  role             = aws_iam_role.iam_for_lambda.arn
  filename         = "pavlov-server-get/pavlov-server-get.zip"
  runtime          = "python3.8"
  handler          = "index.lambda_handler"
  source_code_hash = filebase64sha256("pavlov-server-get/pavlov-server-get.zip")
}
