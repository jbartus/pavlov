terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  required_version = ">= 0.15.4"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

provider "archive" {}

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

resource "aws_iam_role" "pavlov_lambda_execution_role" {
  name = "pavlov-lambda-execution-role"

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
    name = "pavlov-role-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        },
        {
          Action   = ["ec2:RunInstances"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["iam:PassRole"]
          Effect   = "Allow"
          Resource = "${aws_iam_role.pavlov-role.arn}"
        }
      ]
    })
  }
}

data "aws_ssm_parameter" "amzn2-ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_lambda_function" "pavlov-function" {
  function_name    = "pavlov-function"
  role             = aws_iam_role.pavlov_lambda_execution_role.arn
  filename         = "package.zip"
  source_code_hash = filebase64sha256("package.zip")
  runtime          = "python3.8"
  handler          = "index.handler"
  timeout          = 10
  environment {
    variables = {
      SECGRPID = aws_security_group.pavlov-sg.id
      INSTPROF = aws_iam_instance_profile.pavlov-profile.arn
      AMZN2AMI = data.aws_ssm_parameter.amzn2-ami.value
    }
  }
}

resource "aws_lambda_function_url" "pavlov-function-url" {
  function_name      = aws_lambda_function.pavlov-function.function_name
  authorization_type = "NONE"
}
