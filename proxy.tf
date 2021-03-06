resource "aws_ecr_repository" "nginx-proxy" {
  name = "nginx-proxy"
}

resource "aws_ecs_task_definition" "proxy" {
  family = "proxy"
  volume {
    name = "docker-sock"
    host_path = "/var/run/docker.sock"
  }
  container_definitions = <<EOF
[
  {
    "name": "proxy",
    "image": "${aws_ecr_repository.nginx-proxy.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.nginx-proxy.name}:latest",
    "cpu": 10,
    "memory": 128,
    "essential": true,
    "portMappings": [
      {
        "hostPort": 80,
        "containerPort": 80,
        "protocol": "tcp"
      },
      {
        "hostPort": 81,
        "containerPort": 81,
        "protocol": "tcp"
      },
      {
        "hostPort": 443,
        "containerPort": 443,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.nginx-proxy.name}",
        "awslogs-region": "${var.region}"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "docker-sock",
        "containerPath": "/tmp/docker.sock",
        "readOnly": true
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "proxy" {
  name = "proxy"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.proxy.arn}"
  desired_count = 1
}

resource "aws_alb_target_group" "proxy-http" {
  name = "proxy-http"
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_alb_target_group_attachment" "proxy-http" {
  target_group_arn = "${aws_alb_target_group.proxy-http.arn}"
  target_id = "${aws_instance.docker.id}"
  port = 80
}

resource "aws_alb_listener" "proxy-https" {
  load_balancer_arn = "${aws_alb.docker.arn}"
  port = 443
  protocol = "HTTPS"
  certificate_arn = "arn:aws:acm:us-east-1:055326413375:certificate/3687e806-a1c3-443b-b238-613bbb1ecd76"

  default_action {
    target_group_arn = "${aws_alb_target_group.proxy-http.arn}"
    type = "forward"
  }
}

resource "aws_alb_target_group" "proxy-http-redirect" {
  name = "proxy-http-redirect"
  port = 81
  protocol = "HTTP"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_alb_target_group_attachment" "proxy-http-redirect" {
  target_group_arn = "${aws_alb_target_group.proxy-http-redirect.arn}"
  target_id = "${aws_instance.docker.id}"
  port = 81
}

resource "aws_alb_listener" "proxy-http" {
  load_balancer_arn = "${aws_alb.docker.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.proxy-http-redirect.arn}"
    type = "forward"
  }
}

resource "aws_cloudwatch_log_group" "nginx-proxy" {
  name = "Proxy"
}
