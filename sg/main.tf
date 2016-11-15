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
