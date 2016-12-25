output "main" {
    value = ["${aws_route53_zone.main.zone_id}"]
}

output "prod" {
    value = ["${aws_route53_zone.prod.zone_id}"]
}

output "dev" {
    value = ["${aws_route53_zone.dev.zone_id}"]
}
