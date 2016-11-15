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
