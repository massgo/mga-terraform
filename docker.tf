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

resource "aws_ecs_task_definition" "slackin" {
  family = "slackin"
  container_definitions = <<EOF

EOF
}

resource "aws_ecs_service" "slackin" {
  name = "slackin"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.slackin.arn}"
  desired_count = 1
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

resource "aws_alb_target_group" "slackin" {
    name = "slackin"
    port = 80
    protocol = "HTTP"
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_alb_listener" "slackin-https" {
   load_balancer_arn = "${aws_alb.docker.arn}"
   port = "443"
   protocol = "HTTPS"
   /*ssl_policy = "ELBSecurityPolicy-2015-05"*/
   /*certificate_arn = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"*/

   default_action {
     target_group_arn = "${aws_alb_target_group.slackin.arn}"
     type = "forward"
   }
}
