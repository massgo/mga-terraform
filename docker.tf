resource "aws_ecr_repository" "slackin" {
  name = "slackin"
}

resource "aws_ecr_repository_policy" "basic" {
  repository = "${aws_ecr_repository.slackin.name}"
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "Andrew Admin",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::055326413375:user/andrew"
      },
      "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
    },
    {
      "Sid": "Instance Pull",
      "Effect": "Allow",
      "Principal": {
          "AWS": "arn:aws:iam::055326413375:role/ecsInstanceRole"
      },
      "Action": [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
EOF
}

resource "aws_ecs_cluster" "docker" {
  name = "docker"
}

resource "aws_alb" "docker" {
    name = "docker"
    internal = false
    security_groups = ["${aws_security_group.web-prod.id}"]
    subnets = ["${aws_subnet.one.id}", "${aws_subnet.two.id}"]

    enable_deletion_protection = true

    /*access_logs {
        bucket = "${aws_s3_bucket.logs.bucket}"
        prefix = "alb/docker"
    }*/
}

data "aws_acm_certificate" "massgo_wildcard" {
  domain = "*.massgo.org"
}
