resource "aws_ecr_repository" "helloworld" {
  name = "helloworld"
}

resource "aws_ecs_task_definition" "helloworld" {
  family = "helloworld"
  container_definitions = <<EOF
[
  {
    "name": "helloworld",
    "image": "055326413375.dkr.ecr.us-east-1.amazonaws.com/helloworld:latest",
    "cpu": 10,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "hostPort": 81,
        "containerPort": 80,
        "protocol": "tcp"
      }
    ]
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

resource "aws_alb_target_group" "helloworld" {
  name = "helloworld"
  port = 81
  protocol = "HTTP"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_alb_target_group_attachment" "helloworld" {
  target_group_arn = "${aws_alb_target_group.helloworld.arn}"
  target_id = "${aws_instance.docker.id}"
  port = 81
}

resource "aws_alb_listener" "helloworld-http" {
  load_balancer_arn = "${aws_alb.docker.arn}"
  port = "80"
  protocol = "HTTP"
  /*ssl_policy = "ELBSecurityPolicy-2015-05"*/
  /*certificate_arn = "${aws_acm_certificate.massgo_wildcard.arn}"*/
  /*certificate_arn = "arn:aws:acm:us-east-1:055326413375:certificate/3687e806-a1c3-443b-b238-613bbb1ecd76"*/

  default_action {
    target_group_arn = "${aws_alb_target_group.helloworld.arn}"
    type = "forward"
  }
}

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
