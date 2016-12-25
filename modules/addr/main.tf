resource "aws_eip" "ip" {
    instance = "${var.instance_id}"
}

resource "aws_route53_record" "dns"
{
    zone_id = "${var.zone_id}"
    name = "${var.name}."
    type = "A"
    ttl = "300"
    records = ["${aws_eip.ip.public_ip}"]
}
