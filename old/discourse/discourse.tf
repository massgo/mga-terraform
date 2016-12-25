resource "aws_instance" "discourse-prod" {
    ami = "ami-60b6c60a"
    instance_type = "t2.small"
    vpc_security_group_ids = [
        "${module.sg.web-prod}",
        "${module.sg.ssh-gbre}"
    ]
    tags =
    {
        Name = "Discourse Prod"
        environment = "prod"
    }
}

resource "aws_instance" "discourse-dev" {
    ami = "ami-60b6c60a"
    instance_type = "t2.small"
    vpc_security_group_ids = [
        "${module.sg.web-prod}",
        "${module.sg.ssh-gbre}"
    ]
    tags =
    {
        Name = "Discourse Dev"
        environment = "dev"
    }
}

resource "aws_eip" "discourse-prod" {
    instance = "${aws_instance.discourse-prod.id}"
}

resource "aws_eip" "discourse-dev" {
    instance = "${aws_instance.discourse-dev.id}"
}

resource "aws_route53_record" "discourse-prod"
{
    zone_id = "${module.dns.prod}"
    name = "discourse"
    type = "A"
    ttl = "300"
    records = ["${aws_eip.discourse-prod.public_ip}"]
}

resource "aws_route53_record" "discourse-dev"
{
    zone_id = "${module.dns.dev}"
    name = "discourse"
    type = "A"
    ttl = "300"
    records = ["${aws_eip.discourse-dev.public_ip}"]
}

resource "aws_route53_record" "discourse-legacy"
{
    zone_id = "${module.dns.main}"
    name = "discourse"
    type = "A"
    ttl = "300"
    records = ["52.0.246.3"]
}

resource "aws_s3_bucket" "discourse-uploads"
{
    bucket = "massgo-discourse-uploads"
    logging
    {
        target_bucket = "${module.s3.logs}"
        target_prefix = "buckets/massgo-discourse-uploads/"
    }
    versioning
    {
        enabled = true
    }
    lifecycle_rule
    {
        enabled = true
        expiration
        {
            days = "30"
        }
        prefix = "tombstone/"
    }
}

resource "aws_s3_bucket" "discourse-backups"
{
    bucket = "massgo-discourse-backups"
    logging
    {
        target_bucket = "${module.s3.logs}"
        target_prefix = "buckets/massgo-discourse-backups/"
    }
    versioning
    {
        enabled = true
    }
}
