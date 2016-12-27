resource "aws_ecs_task_definition" "slackin" {
  family = "slackin"
  container_definitions = <<EOF
[
  {
    "name": "slackin",
    "image": "055326413375.dkr.ecr.us-east-1.amazonaws.com/slackin:latest",
    "cpu": 10,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "hostPort": 80,
        "containerPort": 3000,
        "protocol": "tcp"
      }
    ]
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
  /*certificate_arn = "${aws_acm_certificate.massgo_wildcard.arn}"*/
  certificate_arn = "arn:aws:acm:us-east-1:055326413375:certificate/3687e806-a1c3-443b-b238-613bbb1ecd76"

  default_action {
    target_group_arn = "${aws_alb_target_group.slackin.arn}"
    type = "forward"
  }
}

resource "aws_route53_record" "slack" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "slack"
  type = "A"

  alias {
    name = "${aws_alb.docker.dns_name}"
    zone_id = "${aws_alb.docker.zone_id}"
    evaluate_target_health = true
  }
}
