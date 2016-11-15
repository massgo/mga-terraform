output "web-prod" {
    value = ["${aws_security_group.web-prod.id}"]
}

output "ssh-gbre" {
    value = ["${aws_security_group.ssh-gbre.id}"]
}
