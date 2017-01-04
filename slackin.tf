resource "aws_route53_record" "slackin" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "slack"
  type = "A"

  alias {
    name = "${aws_alb.docker.dns_name}"
    zone_id = "${aws_alb.docker.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_ecr_repository" "slackin" {
  name = "slackin"
}

resource "aws_ecs_task_definition" "slackin" {
  family = "slackin"
  container_definitions = <<EOF
[
  {
    "name": "slackin",
    "image": "${aws_ecr_repository.slackin.registry_id}.dkr.ecr.us-east-1.amazonaws.com/${aws_ecr_repository.slackin.name}:latest",
    "memory": 128,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.slackin.name}",
        "awslogs-region": "${var.region}"
      }
    },
    "environment": [
      { "name": "VIRTUAL_HOST", "value": "slack.massgo.org"}
    ],
    "essential": true
  }
]
EOF
}

resource "aws_ecs_service" "slackin" {
  name = "slackin"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.slackin.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "slackin" {
  name = "Slackin"
}
