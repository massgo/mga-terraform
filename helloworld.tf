resource "aws_route53_record" "helloworld" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "helloworld"
  type = "A"

  alias {
    name = "${aws_alb.docker.dns_name}"
    zone_id = "${aws_alb.docker.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_ecr_repository" "helloworld" {
  name = "helloworld"
}

resource "aws_ecs_task_definition" "helloworld" {
  family = "helloworld"
  container_definitions = <<EOF
[
  {
    "name": "helloworld",
    "image": "${aws_ecr_repository.helloworld.registry_id}.dkr.ecr.us-east-1.amazonaws.com/${aws_ecr_repository.helloworld.name}:latest",
    "cpu": 10,
    "environment": [
      { "name": "VIRTUAL_HOST", "value": "${aws_route53_record.helloworld.fqdn}"}
    ],
    "memory": 512,
    "essential": true
  }
]
EOF
}

resource "aws_ecs_service" "helloworld" {
  name = "helloworld"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.helloworld.arn}"
  desired_count = 1
}
