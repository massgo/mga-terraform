variable "evening_league_version" {
  default = "0.3.1"
}

resource "aws_route53_record" "evening_league" {
  zone_id = "${aws_route53_zone.root.zone_id}"
  name = "evening-league"
  type = "A"

  alias {
    name = "${aws_alb.docker.dns_name}"
    zone_id = "${aws_alb.docker.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_ecs_task_definition" "evening_league" {
  family = "evening_league"

  volume {
    name = "evening_league-uwsgi"
  }

  volume {
    name = "evening_league-db_data"
    host_path = "/var/lib/evening_league/db"
  }

  container_definitions = <<EOF
[
  {
    "name": "evening_league_app",
    "image": "${aws_ecr_repository.league_app.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_app.name}:${var.evening_league_version}",
    "memory": 256,
    "essential": true,
    "links": ["evening_league_db:db"],
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"},
      {"name": "SERVER_NAME", "value": "evening_league.aws.massgo.org"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.evening_league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "app"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "evening_league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "league_webserver",
    "image": "${aws_ecr_repository.league_webserver.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_webserver.name}:${var.evening_league_version}",
    "memory": 256,
    "environment": [
      { "name": "VIRTUAL_HOST", "value": "evening_league.aws.massgo.org"}
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
        "sourceVolume": "evening_league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "evening_league_db",
    "image": "${aws_ecr_repository.league_db.registry_id}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.league_db.name}:${var.evening_league_version}",
    "memory": 256,
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.evening_league.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "db"
      }
    },
    "portMappings": [
      {
        "hostPort": 5433,
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
        "sourceVolume": "evening_league-db_data",
        "containerPath": "/var/lib/league/db"
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "evening_league" {
  name = "evening_league"
  cluster = "${aws_ecs_cluster.docker.id}"
  task_definition = "${aws_ecs_task_definition.evening_league.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "evening_league" {
  name = "evening_league"
}
