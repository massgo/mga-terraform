resource "aws_ecr_repository" "docker" {
  name = "docker"
}

resource "aws_ecs_cluster" "docker" {
  name = "docker"
}
