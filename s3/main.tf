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
