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
          "AWS": "${aws_iam_role.ecs-instance.arn}"
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

resource "aws_iam_role" "ecs-instance" {
    name = "ecsInstance"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs-instance" {
    name = "ecsInstance"
    role = "${aws_iam_role.ecs-instance.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs-instance" {
  name  = "ecsInstance"
  roles = ["${aws_iam_role.ecs-instance.name}"]
}

resource "aws_security_group" "docker-alb" {
    name = "docker_alb"
    description = "Docker ALB rules"

    tags
    {
        Name = "docker_alb"
    }
}

resource "aws_security_group_rule" "docker_alb_allow_http_in" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.docker-alb.id}"
}

resource "aws_security_group_rule" "docker_alb_allow_https_in" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.docker-alb.id}"
}

resource "aws_security_group_rule" "docker_alb_allow_vpc_out" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
    security_group_id = "${aws_security_group.docker-alb.id}"
}

resource "aws_security_group" "ecs-instance" {
    name = "ecs_instance"
    description = "ECS instance rules"

    egress
    {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound HTTPS traffic (!!!)
    }

    # Allow unfettered communication between ALB and ECS instances
    ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = ["${aws_security_group.docker-alb.id}"]
    }

    # Allow unfettered communication between ALB and ECS instances
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = ["${aws_security_group.docker-alb.id}"]
    }

    tags
    {
        Name = "ecs_instance"
    }
}

resource "aws_instance" "docker" {
    ami = "ami-6df8fe7a"
    instance_type = "t2.small"
    key_name = "${aws_key_pair.massgo_ec2.key_name}"
    iam_instance_profile = "${aws_iam_instance_profile.ecs-instance.name}"

    tags = {
        Name = "Docker"
    }
    monitoring = true

    subnet_id = "${aws_subnet.one.id}"
    vpc_security_group_ids = ["${aws_security_group.ecs-instance.id}",
                              "${aws_security_group.ssh-gbre.id}"]
}

module "docker_address" {
  source = "modules/addr"
  name = "docker"
  instance_id = "${aws_instance.docker.id}"
  zone_id = "${aws_route53_zone.root.id}"
}

resource "aws_alb" "docker" {
    name = "docker"
    internal = false
    security_groups = ["${aws_security_group.docker-alb.id}"]
    subnets = ["${aws_subnet.one.id}", "${aws_subnet.two.id}"]

    enable_deletion_protection = true

    /*access_logs {
        bucket = "${aws_s3_bucket.logs.bucket}"
        prefix = "alb/docker"
    }*/
}
