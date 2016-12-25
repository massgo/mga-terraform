resource "aws_s3_bucket" "bucket"
{
    bucket = "massgo-${var.name}"
    versioning
    {
        enabled = "${var.versioning}"
    }

    logging
    {
        target_bucket = "massgo-${var.log_bucket}"
        target_prefix = "buckets/${var.name}/"
    }
}
