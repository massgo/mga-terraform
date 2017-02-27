variable "league_version" {
  default = "0.3.1"
}

resource "aws_route53_record" "league" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "league"
  type = "A"

  alias {
    name = "${aws_alb.docker.dns_name}"
    zone_id = "${aws_alb.docker.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_ecr_repository" "league_app" {
  name = "league_app"
}

resource "aws_ecr_repository" "league_db" {
  name = "league_db"
}

resource "aws_ecr_repository" "league_webserver" {
  name = "league_webserver"
}

resource "aws_ecs_task_definition" "league" {
  family = "league"

  volume {
    name = "league-uwsgi"
  }

  volume {
    name = "league-db_data"
    host_path = "/var/lib/league/db"
  }

  container_definitions = <<EOF
[
  {
    "name": "league_app",
    "image": "${aws_ecr_repository.league_app.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_app.name}:${var.league_version}",
    "memory": 256,
    "essential": true,
    "links": ["league_db:db"],
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"},
      {"name": "SERVER_NAME", "value": "league.massgo.org"},
      {"name": "SLACK_CHANNEL", "value": "ronin-league"},
      {"name": "SLACK_WEBHOOK", "value": "fake-value-please-update"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "app"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "league_webserver",
    "image": "${aws_ecr_repository.league_webserver.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_webserver.name}:${var.league_version}",
    "memory": 256,
    "environment": [
      { "name": "VIRTUAL_HOST", "value": "league.massgo.org"}
    ],
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "webserver"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "league_db",
    "image": "${aws_ecr_repository.league_db.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_db.name}:${var.league_version}",
    "memory": 256,
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "db"
      }
    },
    "portMappings": [
      {
        "hostPort": 5432,
        "containerPort": 5432,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"}
    ],
    "mountPoints": [
      {
        "sourceVolume": "league-db_data",
        "containerPath": "/var/lib/league/db"
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "league" {
  name = "league"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.league.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "league" {
  name = "League"
}
