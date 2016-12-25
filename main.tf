# Provider
provider "aws" { region = "us-east-1" }


# Data sources
data "terraform_remote_state" "s3" {
    backend = "s3"
    config
    {
        bucket = "${aws_s3_bucket.tfstate.bucket}"
        key = "terraform.tfstate"
        region = "us-east-1"
    }
}


# VPC
resource "aws_vpc" "main" { cidr_block = "172.31.0.0/16" }


# Subnets
resource "aws_subnet" "one" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.0.0/20"

    tags {
        Name = "One"
    }
}

resource "aws_subnet" "two" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.16.0/20"

    tags {
        Name = "Two"
    }
}

resource "aws_subnet" "three" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.32.0/20"

    tags {
        Name = "Three"
    }
}

resource "aws_subnet" "four" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "172.31.48.0/20"

    tags {
        Name = "Four"
    }
}


# Buckets
resource "aws_s3_bucket" "logs" {
    bucket = "massgo-logs"
    versioning { enabled = false }
    acl = "private"
}

resource "aws_s3_bucket" "tfstate" {
    bucket = "massgo-terraform"
    versioning { enabled = true }
    acl = "private"

    logging
    {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/terraform/"
    }
}


# Zones
resource "aws_route53_zone" "root" { name = "aws.massgo.org" }


# Security groups
resource "aws_security_group" "web-prod" {
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

resource "aws_security_group" "ssh-gbre" {
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
