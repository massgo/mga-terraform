###################
#### AWS Conf #####
###################

provider "aws"
{
    region = "us-east-1"
    profile = "massgo"
}


###################
#### DNS Stuff ####
###################

resource "aws_route53_zone" "main"
{
    name = "aws.massgo.org"
}

resource "aws_route53_zone" "prod"
{
    name = "prod.aws.massgo.org"
    tags
    {
        Environment = "prod"
    }
}

resource "aws_route53_zone" "dev"
{
    name = "dev.aws.massgo.org"
    tags
    {
        Environment = "dev"
    }
}

resource "aws_route53_record" "prod-ns"
{
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "prod"
    type = "NS"
    ttl = "300"
    records = [
        "${aws_route53_zone.prod.name_servers.0}",
        "${aws_route53_zone.prod.name_servers.1}",
        "${aws_route53_zone.prod.name_servers.2}",
        "${aws_route53_zone.prod.name_servers.3}"
    ]
}

resource "aws_route53_record" "dev-ns"
{
    zone_id = "${aws_route53_zone.main.zone_id}"
    name = "dev"
    type = "NS"
    ttl = "300"
    records = [
        "${aws_route53_zone.dev.name_servers.0}",
        "${aws_route53_zone.dev.name_servers.1}",
        "${aws_route53_zone.dev.name_servers.2}",
        "${aws_route53_zone.dev.name_servers.3}"
    ]
}


#####################
#### S3 Buckets  ####
#####################

resource "aws_s3_bucket" "logs"
{
    bucket = "massgo-logs"
    acl = "log-delivery-write"
    logging
    {
        target_bucket = "massgo-logs"
        target_prefix = "buckets/massgo-logs/"
    }
}

resource "aws_s3_bucket" "tf-state"
{
    bucket = "massgo-terraform"
    versioning
    {
        enabled = true
    }
    logging
    {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/massgo-terraform/"
    }
}


#####################
##### TF State ######
#####################

resource "terraform_remote_state" "s3"
{
    backend = "s3"
    config
    {
        bucket = "${aws_s3_bucket.tf-state.bucket}"
        key = "terraform.tfstate"
        region = "us-east-1"
        profile = "massgo"
    }
}


#####################
#### Sec. Groups ####
#####################

resource "aws_security_group" "web-prod"
{
    name = "web_prod"
    description = "Allow inbound HTTP/S traffic from anywhere"

    ingress
    {
        from_port = 0
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress
    {
        from_port = 0
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags
    {
        Name = "web_prod"
    }
}

resource "aws_security_group" "ssh-gbre"
{
    name = "ssh_gbre"
    description = "Allow SSH traffic from gbre.org"

    ingress
    {
        from_port = 0
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["73.234.173.33/32"]
    }

    tags
    {
        Name = "ssh_gbre"
    }
}
