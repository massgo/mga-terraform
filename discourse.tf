resource "aws_instance" "discourse" {
    ami = "ami-60b6c60a"
    instance_type = "t2.small"

    tags = {
        Name = "Discourse"
    }

    monitoring = true
    vpc_security_group_ids = [
      "${aws_security_group.web-prod.id}",
      "${aws_security_group.ssh-gbre.id}",
      "${aws_security_group.outbound-all.id}"
    ]
}

module "discourse_address" {
  source = "modules/addr"
  name = "discourse"
  instance_id = "${aws_instance.discourse.id}"
  zone_id = "${aws_route53_zone.root.id}"
}

resource "aws_s3_bucket" "discourse_uploads" {
    bucket = "massgo-discourse-uploads"
    versioning { enabled = true }
    acl = "public_read"

    lifecycle_rule = {
        id = "purge-tombstone"
        prefix = "tombstone/"
        enabled = true
        expiration = { days = 30 }
    }

    logging {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/discourse-uploads/"
    }
}

resource "aws_s3_bucket" "discourse_backups" {
    bucket = "massgo-discourse-backups"
    versioning { enabled = true }
    acl = "private"

    logging {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/discourse-backups/"
    }
}
