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
    host_path = "/tmp/league-uwsgi/"
  }
  container_definitions = <<EOF
[
  {
    "name": "league_app",
    "image": "${aws_ecr_repository.league_app.registry_id}.dkr.ecr.us-east-1.amazonaws.com/${aws_ecr_repository.league_app.name}:latest",
    "cpu": 10,
    "memory": 256,
    "essential": true,
    "links": ["league_db:db"],
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"}
    ],
    "mountPoints": [
      {
        "sourceVolume": "league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "league_webserver",
    "image": "${aws_ecr_repository.league_webserver.registry_id}.dkr.ecr.us-east-1.amazonaws.com/${aws_ecr_repository.league_webserver.name}:latest",
    "cpu": 10,
    "memory": 256,
    "environment": [
      { "name": "VIRTUAL_HOST", "value": "league.massgo.org"}
    ],
    "essential": true,
    "mountPoints": [
      {
        "sourceVolume": "league-uwsgi",
        "containerPath": "/tmp/uwsgi"
      }
    ]
  },
  {
    "name": "league_db",
    "image": "${aws_ecr_repository.league_db.registry_id}.dkr.ecr.us-east-1.amazonaws.com/${aws_ecr_repository.league_db.name}:latest",
    "cpu": 10,
    "memory": 256,
    "essential": true,
    "environment": [
      {"name": "POSTGRES_USER", "value": "league"},
      {"name": "POSTGRES_PASSWORD", "value": "league"},
      {"name": "POSTGRES_DB", "value": "league"}
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
